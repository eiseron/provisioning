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

if failures.empty?
  puts "tofu observability password policy: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
