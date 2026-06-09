#!/usr/bin/env bash
set -euo pipefail

APP_IMAGE_REF="${1:?app image ref present in the local docker daemon}"
VERSION="${2:?version, e.g. v0.1.5}"

HERE="$(cd "$(dirname "$0")" && pwd)"
KAMAL_DIR="$(cd "$HERE/../../../kamal" && pwd)"
NET=kamal-e2e
HOST=kamal-e2e-host
OPS_IMAGE="${OPS_IMAGE:-registry.gitlab.com/eiseron/stack/public-image-bases/ops:v0.1.15}"
TENANT="${TENANT:-afinados}"
TENANT_DB="${TENANT}_prod"
TENANT_PW="${TENANT_PW:-tenantpw}"
ADMIN_PW="${ADMIN_PW:-adminpw}"
WORK="$(mktemp -d)"

cleanup() {
  docker rm -f "$HOST" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
  rm -rf "$WORK" "$HERE/host/deploy_key.pub"
}
trap cleanup EXIT

echo "== ephemeral ssh key + host image =="
ssh-keygen -t ed25519 -N "" -f "$WORK/deploy_key" -C kamal-e2e >/dev/null
cp "$WORK/deploy_key.pub" "$HERE/host/deploy_key.pub"
docker build -q -t "$HOST" "$HERE/host" >/dev/null

echo "== start host (dind + sshd) =="
docker network create "$NET" >/dev/null 2>&1 || true
docker rm -f "$HOST" >/dev/null 2>&1 || true
docker run -d --privileged --name "$HOST" --network "$NET" --network-alias "$HOST" "$HOST" >/dev/null
for _ in $(seq 1 30); do docker exec "$HOST" docker info >/dev/null 2>&1 && break; sleep 1; done
docker exec "$HOST" sh -c 'mkdir -p /var/lib/crypt && chown deploy:deploy /var/lib/crypt'

echo "== local registry + images =="
docker exec "$HOST" docker run -d --name reg --restart always -p 5000:5000 registry:2 >/dev/null
sleep 2
docker save "$APP_IMAGE_REF" | docker exec -i "$HOST" docker load >/dev/null
docker exec "$HOST" sh -c "docker tag '$APP_IMAGE_REF' localhost:5000/${TENANT}/prod:$VERSION && docker push -q localhost:5000/${TENANT}/prod:$VERSION >/dev/null"
docker exec "$HOST" sh -c 'docker pull -q busybox >/dev/null && docker tag busybox localhost:5000/platform/noop && docker push -q localhost:5000/platform/noop >/dev/null'

run_kamal() {
  local proj="$1"; shift
  docker run --rm --network "$NET" \
    -v "$KAMAL_DIR/$proj":/work -w /work -v "$WORK/deploy_key":/tmp/deploy_key:ro \
    -e KAMAL_REGISTRY_USERNAME=x -e KAMAL_REGISTRY_PASSWORD=x \
    -e KAMAL_REGISTRY_SERVER=localhost:5000 \
    -e PROD_HOST="$HOST" -e PROXY_SSL=false \
    -e POSTGRES_PASSWORD="$ADMIN_PW" \
    -e APP_SERVICE="$TENANT" -e APP_IMAGE="${TENANT}/prod" -e APP_HOST=app.afinados.io \
    -e APP_RELEASE_MODULE="$(printf '%s' "$TENANT" | sed 's/.*/\u&/')" \
    -e SECRET_KEY_BASE="$(head -c 48 /dev/urandom | base64 | tr -d '\n')" \
    -e DATABASE_URL="ecto://${TENANT}:${TENANT_PW}@platform-db:5432/${TENANT_DB}" \
    "$OPS_IMAGE" bash -c '
      set -e
      export PATH="$(ruby -e "print Gem.user_dir")/bin:$PATH"
      eval "$(ssh-agent -s)" >/dev/null
      install -d -m 700 ~/.ssh; install -m 600 /tmp/deploy_key ~/.ssh/id_ed25519
      ssh-add ~/.ssh/id_ed25519 2>/dev/null
      printf "Host *\n  StrictHostKeyChecking accept-new\n" > ~/.ssh/config
      '"$*"
}

echo "== platform: shared postgres + kamal-proxy =="
run_kamal platform 'kamal accessory boot db --version=v1 && kamal proxy boot --version=v1'

echo "== tenant: DB + login role in the shared postgres =="
psql_admin() { docker exec "$HOST" docker exec -e PGPASSWORD="$ADMIN_PW" platform-db psql -U eiseron -d postgres -v ON_ERROR_STOP=1 "$@"; }
psql_admin -tAc "SELECT 1 FROM pg_roles WHERE rolname='${TENANT}'" | grep -q 1 \
  || psql_admin -c "CREATE ROLE ${TENANT} LOGIN PASSWORD '${TENANT_PW}';"
psql_admin -tAc "SELECT 1 FROM pg_database WHERE datname='${TENANT_DB}'" | grep -q 1 \
  || psql_admin -c "CREATE DATABASE ${TENANT_DB} OWNER ${TENANT};"

echo "== product: app-only deploy (registers with shared proxy) =="
run_kamal app "kamal deploy --version=$VERSION --skip-push"

echo "== assertions =="
fail=0
status=$(docker run --rm --network "$NET" curlimages/curl -s -o /dev/null -w '%{http_code}' -H "Host: app.afinados.io" "http://$HOST/up")
[ "$status" = "200" ] && echo "PASS  /up via shared kamal-proxy = 200" || { echo "FAIL  /up = $status"; fail=1; }
migs=$(docker exec "$HOST" docker exec -e PGPASSWORD="$ADMIN_PW" platform-db psql -U eiseron -d "$TENANT_DB" -tAc "select count(*) from schema_migrations")
[ "${migs:-0}" -ge 1 ] && echo "PASS  migrations applied in shared DB ($migs in schema_migrations)" || { echo "FAIL  no migrations"; fail=1; }

[ "$fail" = 0 ] && echo "== E2E PASSED ==" || echo "== E2E FAILED =="
exit $fail
