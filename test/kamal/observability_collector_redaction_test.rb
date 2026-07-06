# frozen_string_literal: true

require "yaml"

CONFIG = File.expand_path("../../kamal/observability/config/otel-collector.yaml", __dir__)
doc = YAML.safe_load(File.read(CONFIG))

failures = []
def expect(failures, description)
  failures << description unless yield
end

redaction = doc.dig("processors", "redaction")
expect(failures, "processor redaction existe") { !redaction.nil? }
expect(failures, "redaction mantem as chaves e mascara os valores (allow_all_keys)") do
  redaction && redaction["allow_all_keys"] == true
end

key_patterns = Array(redaction && redaction["blocked_key_patterns"]).join(" ")
expect(failures, "redaction cobre secrets (password/token/authorization)") do
  %w[password token authorization].all? { |k| key_patterns.include?(k) }
end
expect(failures, "redaction cobre PII (cpf/email/telefone)") do
  %w[cpf mail telefone].all? { |k| key_patterns.include?(k) }
end
expect(failures, "redaction cobre PHI (patient/ecg/laudo) mesmo com holter fora do store hoje") do
  %w[patient ecg laudo].all? { |k| key_patterns.include?(k) }
end

blocked_values = Array(redaction && redaction["blocked_values"]).join(" ")
expect(failures, "redaction mascara valores por regex (email e cpf), nao so por nome de chave") do
  blocked_values.include?("@") && blocked_values.include?('\d{3}')
end

%w[logs traces].each do |pipeline|
  procs = Array(doc.dig("service", "pipelines", pipeline, "processors"))
  expect(failures, "pipeline #{pipeline} passa pelo redaction antes de exportar") do
    procs.first == "redaction" && procs.include?("batch")
  end
end

metrics_procs = Array(doc.dig("service", "pipelines", "metrics", "processors"))
expect(failures, "metricas nao pagam o custo do redaction (operacionais, sem PII)") do
  !metrics_procs.include?("redaction")
end

if failures.empty?
  puts "otel-collector redaction: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
