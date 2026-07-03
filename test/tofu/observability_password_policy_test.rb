# frozen_string_literal: true

MAIN = File.expand_path("../../modules/observability/main.tf", __dir__)
source = File.read(MAIN)

failures = []
def expect(failures, description)
  failures << description unless yield
end

root_block = source[/resource\s+"random_password"\s+"root"\s*\{(.*?)\n\}/m, 1] || ""

expect(failures, "random_password.root existe") { !root_block.empty? }
expect(failures, "senha root habilita caractere especial (OpenObserve rejeita senha sem especial)") do
  root_block.match?(/special\s*=\s*true/) && !root_block.match?(/special\s*=\s*false/)
end
expect(failures, "comprimento da senha root permanece 32") do
  root_block.match?(/length\s*=\s*32/)
end
%w[min_lower min_upper min_numeric min_special].each do |constraint|
  expect(failures, "senha root exige #{constraint} >= 1 (politica de complexidade do OpenObserve)") do
    root_block.match?(/#{constraint}\s*=\s*[1-9]/)
  end
end

expect(failures, "OBSERVABILITY_ROOT_PASSWORD entregue como variavel masked") do
  source.match?(/OBSERVABILITY_ROOT_PASSWORD\s*=\s*\{[^}]*masked\s*=\s*true/)
end
expect(failures, "OBSERVABILITY_OTLP_BASIC (carrega a senha) entregue como masked") do
  source.match?(/OBSERVABILITY_OTLP_BASIC\s*=.*masked\s*=\s*true/)
end
expect(failures, "senha root usa a var do consumidor com fallback para a random gerada") do
  source.match?(/root_pw\s*=\s*nonsensitive\(var\.root_password\s*!=\s*""\)\s*\?\s*var\.root_password\s*:\s*random_password\.root\.result/)
end
expect(failures, "ROOT_PASSWORD e OTLP_BASIC usam o mesmo root_pw (senha do usuario OU random)") do
  source.match?(/OBSERVABILITY_ROOT_PASSWORD\s*=\s*\{\s*value\s*=\s*local\.root_pw/) &&
    source.match?(/OBSERVABILITY_OTLP_BASIC\s*=\s*\{\s*value\s*=\s*base64encode\("\$\{var\.root_email\}:\$\{local\.root_pw\}"\)/)
end

if failures.empty?
  puts "tofu observability password policy: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
