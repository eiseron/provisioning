# frozen_string_literal: true

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/error-monitoring/config/deploy.yml", __dir__)

BASE = {
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.gitlab.com",
  "ERROR_MONITORING_HOST" => "errors.eiseron.com"
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
expect(failures, "imagem sai do nosso registry (platform/error-monitoring), nao do Docker Hub") do
  manifest["image"] == "registry.gitlab.com/platform/error-monitoring"
end
expect(failures, "imagem nao usa :latest") { !manifest["image"].to_s.end_with?(":latest") }

secret = manifest.dig("env", "secret") || []
clear = (manifest.dig("env", "clear") || {}).keys
expect(failures, "SECRET_KEY e DATABASE_URL ficam sob secret") do
  %w[SECRET_KEY DATABASE_URL].all? { |k| secret.include?(k) }
end
expect(failures, "segredos nunca em clear") do
  (clear & %w[SECRET_KEY DATABASE_URL]).empty?
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
