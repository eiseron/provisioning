# frozen_string_literal: true

# Renderiza o platform/config/deploy.yml (ERB) nos dois estados do accessory
# de backup (opt-in via PROD_BACKUP_BUCKET) e afirma a estrutura resultante,
# evitando regressao de YAML quando as variaveis estao ausentes.

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/platform/config/deploy.yml", __dir__)

BASE = {
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.gitlab.com"
}.freeze

BACKUP = {
  "PROD_BACKUP_BUCKET" => "afinados-backups",
  "PROD_BACKUP_NAME" => "afinados",
  "PROD_BACKUP_AGE_RECIPIENTS" => "age1aaa,age1bbb",
  "CLOUDFLARE_ACCOUNT_ID" => "acct"
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

off = render(BASE)
expect(failures, "backup desligado: somente o accessory db") { off["accessories"].keys == ["db"] }

on = render(BASE.merge(BACKUP))
backup = on.dig("accessories", "backup") || {}
expect(failures, "backup ligado: accessory backup presente") { on["accessories"].key?("backup") }
expect(failures, "cmd roda o scheduler") { backup["cmd"] == "eiseron db backup schedule" }
expect(failures, "imagem fixada por versao (sem :latest)") { backup["image"].to_s.match?(%r{automation:v\d+\.\d+\.\d+\z}) }
expect(failures, "PGHOST aponta para o accessory db") { backup.dig("env", "clear", "PGHOST") == "platform-db" }
expect(failures, "PGUSER e o papel admin") { backup.dig("env", "clear", "PGUSER") == "eiseron" }
expect(failures, "PROD_BACKUP_DATABASE e a base _prod do produto") { backup.dig("env", "clear", "PROD_BACKUP_DATABASE") == "afinados_prod" }
expect(failures, "credenciais ficam sob secret, nunca em clear") do
  secret = backup.dig("env", "secret") || []
  %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY PGPASSWORD].all? { |key| secret.include?(key) }
end

if failures.empty?
  puts "kamal render: OK (backup on/off)"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
