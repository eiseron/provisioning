# Kamal production-topology e2e

Validates the production deploy topology off production, on a throwaway dind
host: the **platform** (shared postgres accessory + kamal's native shared
proxy, `kamal-proxy`) and a **product** (app-only `kamal deploy` that registers
with the shared proxy and connects to a per-product DB + role in the shared
postgres). Asserts the app is reachable through the proxy (`/up` = 200) and its
migrations ran in the shared database.

## Run

    ./run.sh <app-image-ref> <version>

`<app-image-ref>` is a release image already present in the local docker daemon
(the product's `Dockerfile.prod` output, carrying the kamal `service` label and
a `/up` health endpoint). Example:

    ./run.sh afinados/prod:local v0.1.5

The host, registry, network and SSH key are ephemeral and torn down on exit.

## What it proves

- `kamal accessory boot` brings up the shared postgres on the encrypted root.
- `kamal proxy boot` brings up the shared kamal-proxy (kamal 2's native proxy).
- a per-product DB + login role is created in the shared postgres.
- an app-only product deploy (`proxy:` host, no accessories) registers with the
  shared proxy and reaches the shared DB; the post-deploy hook migrates it.
