# frozen_string_literal: true

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/observability/config/deploy.yml", __dir__)

BASE = {
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.example",
  "OBSERVABILITY_IMAGE" => "registry.example/org/observability",
  "OBSERVABILITY_HOST" => "observe.example.test",
  "CI_COMMIT_SHORT_SHA" => "abc1234",
  "OBSERVABILITY_ROOT_EMAIL" => "ops@example.test",
  "OBSERVABILITY_R2_ENDPOINT" => "https://acct.r2.example.test",
  "OBSERVABILITY_R2_BUCKET" => "eiseron-observability"
}.freeze

def render(env)
  saved = ENV.to_h
  env.each { |key, value| ENV[key] = value }
  YAML.safe_load(ERB.new(File.read(DEPLOY)).result)
ensure
  ENV.replace(saved)
end

failures = []
def expect(failures, description)
  failures << description unless yield
end

manifest = render(BASE)

expect(failures, "service e observability") { manifest["service"] == "observability" }
expect(failures, "imagem respeita o OBSERVABILITY_IMAGE") do
  manifest["image"] == "registry.example/org/observability"
end
expect(failures, "imagem nao usa :latest") { !manifest["image"].to_s.end_with?(":latest") }

fallback = render(BASE.reject { |key, _| key == "OBSERVABILITY_IMAGE" })
expect(failures, "sem OBSERVABILITY_IMAGE, imagem cai no default do registry (interpolacao ERB aninhada)") do
  fallback["image"] == "registry.example/platform/observability"
end

secret = manifest.dig("env", "secret") || []
clear = (manifest.dig("env", "clear") || {}).keys
expect(failures, "senha root, chaves S3 do R2 e senha SMTP ficam sob secret") do
  %w[ZO_ROOT_USER_PASSWORD ZO_S3_ACCESS_KEY ZO_S3_SECRET_KEY ZO_SMTP_PASSWORD].all? { |k| secret.include?(k) }
end
expect(failures, "segredos nunca em clear (chaves R2, senha root e SMTP)") do
  (clear & %w[ZO_ROOT_USER_PASSWORD ZO_S3_ACCESS_KEY ZO_S3_SECRET_KEY ZO_SMTP_PASSWORD]).empty?
end

expect(failures, "storage aponta para S3/R2") do
  manifest.dig("env", "clear", "ZO_LOCAL_MODE_STORAGE") == "s3"
end
expect(failures, "telemetria externa do OpenObserve desligada") do
  manifest.dig("env", "clear", "ZO_TELEMETRY") == "false"
end
expect(failures, "endpoint e bucket do R2 vem do env do consumidor") do
  manifest.dig("env", "clear", "ZO_S3_SERVER_URL") == "https://acct.r2.example.test" &&
    manifest.dig("env", "clear", "ZO_S3_BUCKET_NAME") == "eiseron-observability"
end
expect(failures, "root email vem do env (sem literal no manifesto)") do
  manifest.dig("env", "clear", "ZO_ROOT_USER_EMAIL") == "ops@example.test"
end
fallback_email = render(BASE.reject { |key, _| key == "OBSERVABILITY_ROOT_EMAIL" })
expect(failures, "sem OBSERVABILITY_ROOT_EMAIL, cai no default generico") do
  fallback_email.dig("env", "clear", "ZO_ROOT_USER_EMAIL") == "root@example.test"
end

expect(failures, "healthcheck aponta para /healthz") do
  manifest.dig("proxy", "healthcheck", "path") == "/healthz"
end
expect(failures, "proxy expoe a porta 5080 do OpenObserve") do
  manifest.dig("proxy", "app_port") == 5080
end

expect(failures, "dados persistem em diretorio crypt do host") do
  (manifest["volumes"] || []).any? { |v| v.end_with?(":/data") && v.include?("/var/lib/crypt/observability") }
end

collector = manifest.dig("accessories", "collector") || {}
expect(failures, "accessory collector usa otel-collector-contrib pinado por digest") do
  collector["image"].to_s.start_with?("otel/opentelemetry-collector-contrib@sha256:")
end
expect(failures, "collector nao usa :latest") { !collector["image"].to_s.end_with?(":latest") }
expect(failures, "auth do OTLP para o OpenObserve fica sob secret do collector") do
  (collector.dig("env", "secret") || []).include?("OBSERVABILITY_OTLP_AUTH")
end
expect(failures, "collector encaminha direto ao container do OpenObserve na rede kamal (http interno; evita o ufw/proxy do host)") do
  collector.dig("env", "clear", "OBSERVABILITY_OTLP_ENDPOINT") == "http://observability-web-abc1234:5080/api/default"
end
expect(failures, "collector nao usa mais add-host/host-gateway (o caminho pelo host era bloqueado pelo ufw)") do
  (collector.dig("options", "add-host") || []).empty?
end

node = manifest.dig("accessories", "node-exporter") || {}
expect(failures, "accessory node-exporter pinado por digest") do
  node["image"].to_s.start_with?("prom/node-exporter@sha256:")
end
expect(failures, "node-exporter fica na rede interna kamal (nao exposto no host; metricas do host vem via mounts de procfs/sysfs)") do
  node["network"] == "kamal"
end
expect(failures, "node-exporter le o host via procfs/sysfs montados (metricas reais sem host network)") do
  (node["volumes"] || []).any? { |v| v.start_with?("/proc:/host/proc") } &&
    node["cmd"].to_s.include?("--path.procfs=/host/proc")
end
expect(failures, "collector scrapa o node-exporter pelo nome estavel de accessory (interno)") do
  collector.dig("env", "clear", "OBSERVABILITY_NODE_TARGET") == "observability-node-exporter:9100"
end

cadvisor = manifest.dig("accessories", "cadvisor") || {}
expect(failures, "accessory cadvisor pinado por digest") do
  cadvisor["image"].to_s.start_with?("gcr.io/cadvisor/cadvisor@sha256:")
end
expect(failures, "exporters nao usam :latest") do
  [node["image"], cadvisor["image"]].none? { |i| i.to_s.end_with?(":latest") }
end
expect(failures, "cadvisor nao roda privileged (least-privilege)") do
  cadvisor.dig("options", "privileged").nil?
end
expect(failures, "cadvisor usa cap-add SYS_PTRACE + no-new-privileges no lugar de privileged") do
  (cadvisor.dig("options", "cap-add") || []).include?("SYS_PTRACE") &&
    (cadvisor.dig("options", "security-opt") || []).include?("no-new-privileges")
end
expect(failures, "exporters tem limite de memoria (evita noisy-neighbor)") do
  !node.dig("options", "memory").nil? && !cadvisor.dig("options", "memory").nil?
end
expect(failures, "cmd de accessory sem metacaractere de shell perigoso: ( ) | ; & < > $ ` (kamal monta o docker run sem aspas; escopo = os que quebram/injetam no bash)") do
  (manifest["accessories"] || {}).values.none? do |acc|
    acc.is_a?(Hash) && acc["cmd"].to_s.match?(/[()|;&<>$`]/)
  end
end
expect(failures, "node-exporter mantem mount-points-exclude (nao dropar = evita double-count dos bind-mounts /host)") do
  node["cmd"].to_s.include?("--collector.filesystem.mount-points-exclude=")
end

postgres = manifest.dig("accessories", "postgres-exporter") || {}
expect(failures, "accessory postgres-exporter pinado por digest") do
  postgres["image"].to_s.start_with?("quay.io/prometheuscommunity/postgres-exporter@sha256:")
end
expect(failures, "postgres-exporter nao usa :latest") { !postgres["image"].to_s.end_with?(":latest") }
expect(failures, "postgres-exporter fica na rede interna kamal (alcanca o platform-db sem expor porta)") do
  postgres["network"] == "kamal"
end
expect(failures, "DSN do postgres-exporter (com a senha da role) fica sob secret, nunca em clear") do
  (postgres.dig("env", "secret") || []).include?("DATA_SOURCE_NAME") &&
    !(postgres.dig("env", "clear") || {}).key?("DATA_SOURCE_NAME")
end
expect(failures, "postgres-exporter tem limite de memoria e no-new-privileges (least-privilege)") do
  !postgres.dig("options", "memory").nil? &&
    (postgres.dig("options", "security-opt") || []).include?("no-new-privileges")
end
expect(failures, "collector scrapa o postgres-exporter pelo nome estavel de accessory (interno)") do
  collector.dig("env", "clear", "OBSERVABILITY_POSTGRES_TARGET") == "observability-postgres-exporter:9187"
end

dsn_line = File.readlines(File.expand_path("../../kamal/observability/.kamal/secrets", __dir__))
               .grep(/DATA_SOURCE_NAME/).first.to_s
expect(failures, "DSN do postgres-exporter nao desliga TLS (sslmode=prefer usa TLS assim que o platform-db tiver cert)") do
  dsn_line.include?("sslmode=") && !dsn_line.include?("sslmode=disable")
end

if failures.empty?
  puts "kamal render observability: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
