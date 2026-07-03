# frozen_string_literal: true

# Renderiza kamal/app/config/deploy.yml (ERB) nos dois estados do accessory
# de backup (opt-in via PROD_BACKUP_BUCKET) e afirma os invariantes:
# opt-in on/off, imagem pinada por versao (sem :latest), e creds sob secret.

require "erb"
require "yaml"

DEPLOY = File.expand_path("../../kamal/app/config/deploy.yml", __dir__)

BASE = {
  "APP_SERVICE" => "afinados",
  "APP_IMAGE" => "registry.example/afinados",
  "APP_HOST" => "app.afinados.io",
  "PROD_HOST" => "10.0.0.1",
  "KAMAL_REGISTRY_SERVER" => "registry.gitlab.com"
}.freeze

BACKUP = {
  "PROD_BACKUP_BUCKET" => "afinados-backups",
  "PROD_TENANT_SLUG" => "afinados",
  "CLOUDFLARE_ACCOUNT_ID" => "acct",
  "PROD_BACKUP_AGE_RECIPIENTS" => "age1aaa,age1bbb"
}.freeze

ADMIN = {
  "ADMIN_ACCESS_AUDIENCES" => "aud123",
  "ADMIN_ACCESS_ISSUER" => "https://team.cloudflareaccess.com",
  "ADMIN_ACCESS_CERTS_URL" => "https://team.cloudflareaccess.com/cdn-cgi/access/certs"
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
expect(failures, "backup desligado: sem accessory backup") { (off["accessories"] || {}).key?("backup") == false }

on = render(BASE.merge(BACKUP))
backup = on.dig("accessories", "backup") || {}
expect(failures, "backup ligado: accessory backup presente") { on.fetch("accessories", {}).key?("backup") }
expect(failures, "cmd roda o scheduler") { backup["cmd"] == "eiseron db backup schedule" }
expect(failures, "imagem fixada por versao (sem :latest)") { backup["image"].to_s.match?(/:v\d+\.\d+\.\d+\z/) }
expect(failures, "PGHOST aponta para o container do db") { !backup.dig("env", "clear", "PGHOST").to_s.empty? }
expect(failures, "credenciais ficam sob secret, nunca em clear") do
  secret = backup.dig("env", "secret") || []
  clear = (backup.dig("env", "clear") || {}).keys
  %w[PGPASSWORD AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY].all? { |k| secret.include?(k) } &&
    (clear & %w[PGPASSWORD AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY]).empty?
end

admin_off = render(BASE)
expect(failures, "admin gate desligado: sem ADMIN_ACCESS no clear") do
  (admin_off.dig("env", "clear") || {}).keys.none? { |k| k.start_with?("ADMIN_ACCESS") }
end
expect(failures, "admin gate desligado: sem ADMIN_ACCESS no secret") do
  (admin_off.dig("env", "secret") || []).none? { |k| k.start_with?("ADMIN_ACCESS") }
end

admin_on = render(BASE.merge(ADMIN))
expect(failures, "admin gate ligado: issuer e certs url em clear") do
  clear = admin_on.dig("env", "clear") || {}
  clear.key?("ADMIN_ACCESS_ISSUER") && clear.key?("ADMIN_ACCESS_CERTS_URL")
end
expect(failures, "admin gate ligado: audiences sob secret, nunca em clear") do
  secret = admin_on.dig("env", "secret") || []
  clear = (admin_on.dig("env", "clear") || {}).keys
  secret.include?("ADMIN_ACCESS_AUDIENCES") && !clear.include?("ADMIN_ACCESS_AUDIENCES")
end

if failures.empty?
  puts "kamal render: OK (backup + admin gate on/off)"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
