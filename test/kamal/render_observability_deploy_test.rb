# frozen_string_literal: true

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/observability/config/deploy.yml", __dir__)

BASE = {
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.example",
  "OBSERVABILITY_IMAGE" => "registry.example/org/observability",
  "OBSERVABILITY_HOST" => "observe.example.test",
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
expect(failures, "senha root e chaves S3 do R2 ficam sob secret") do
  %w[ZO_ROOT_USER_PASSWORD ZO_S3_ACCESS_KEY ZO_S3_SECRET_KEY].all? { |k| secret.include?(k) }
end
expect(failures, "segredos nunca em clear (chaves R2 e senha root)") do
  (clear & %w[ZO_ROOT_USER_PASSWORD ZO_S3_ACCESS_KEY ZO_S3_SECRET_KEY]).empty?
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

if failures.empty?
  puts "kamal render observability: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
