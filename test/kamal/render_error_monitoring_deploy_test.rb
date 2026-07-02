# frozen_string_literal: true

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/error-monitoring/config/deploy.yml", __dir__)

BASE = {
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.example",
  "ERROR_MONITORING_IMAGE" => "registry.example/org/error-monitoring",
  "ERROR_MONITORING_HOST" => "errors.example.test",
  "ERROR_MONITORING_FROM_EMAIL" => "alerts@example.test"
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

expect(failures, "service e error-monitoring") { manifest["service"] == "error-monitoring" }
expect(failures, "imagem respeita o ERROR_MONITORING_IMAGE") do
  manifest["image"] == "registry.example/org/error-monitoring"
end
expect(failures, "imagem nao usa :latest") { !manifest["image"].to_s.end_with?(":latest") }

fallback = render(BASE.reject { |key, _| key == "ERROR_MONITORING_IMAGE" })
expect(failures, "sem ERROR_MONITORING_IMAGE, imagem cai no default do registry (interpolacao ERB aninhada)") do
  fallback["image"] == "registry.example/platform/error-monitoring"
end

secret = manifest.dig("env", "secret") || []
clear = (manifest.dig("env", "clear") || {}).keys
expect(failures, "SECRET_KEY, DATABASE_URL e EMAIL_URL ficam sob secret") do
  %w[SECRET_KEY DATABASE_URL EMAIL_URL].all? { |k| secret.include?(k) }
end
expect(failures, "segredos nunca em clear (EMAIL_URL carrega a senha SMTP)") do
  (clear & %w[SECRET_KEY DATABASE_URL EMAIL_URL]).empty?
end
expect(failures, "from vem do env do consumidor (sem literal no manifesto)") do
  manifest.dig("env", "clear", "DEFAULT_FROM_EMAIL") == "alerts@example.test"
end
fallback_from = render(BASE.reject { |key, _| key == "ERROR_MONITORING_FROM_EMAIL" })
expect(failures, "sem ERROR_MONITORING_FROM_EMAIL, from cai no default generico do manifesto") do
  fallback_from.dig("env", "clear", "DEFAULT_FROM_EMAIL") == "webmaster@localhost"
end

expect(failures, "registro de usuario desabilitado") do
  manifest.dig("env", "clear", "ENABLE_USER_REGISTRATION") == "false"
end
expect(failures, "criacao de organizacao desabilitada") do
  manifest.dig("env", "clear", "ENABLE_ORGANIZATION_CREATION") == "false"
end

redis = manifest.dig("accessories", "redis") || {}
expect(failures, "accessory redis usa valkey") { redis["image"].to_s.start_with?("valkey/valkey:") }

expect(failures, "healthcheck aponta para /_health/") do
  manifest.dig("proxy", "healthcheck", "path") == "/_health/"
end

if failures.empty?
  puts "kamal render error-monitoring: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
