# frozen_string_literal: true

ORG_CF   = File.expand_path("../../modules/organization/cloudflare.tf", __dir__)
ORG_VARS = File.expand_path("../../modules/organization/variables.tf", __dir__)
ORG_TF   = File.expand_path("../../modules/organization/terraform.tf", __dir__)

org_cf   = File.read(ORG_CF)
org_vars = File.read(ORG_VARS)
org_tf   = File.read(ORG_TF)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "cloudflare_zero_trust_access_identity_provider.otp exists in organization/cloudflare.tf") do
  org_cf.match?(/resource\s+"cloudflare_zero_trust_access_identity_provider"\s+"otp"/)
end

expect(failures, "otp_identity_provider is count-guarded by otp_idp_enabled") do
  org_cf.match?(/cloudflare_zero_trust_access_identity_provider[\s\S]*?count\s*=\s*local\.otp_idp_enabled\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "otp_identity_provider uses account_id from var.cloudflare_account_id") do
  org_cf.match?(/cloudflare_zero_trust_access_identity_provider[\s\S]*?account_id\s*=\s*var\.cloudflare_account_id/m)
end

expect(failures, "otp_identity_provider has type onetimepin") do
  org_cf.match?(/cloudflare_zero_trust_access_identity_provider[\s\S]*?type\s*=\s*"onetimepin"/m)
end

expect(failures, "otp_identity_provider has prevent_destroy lifecycle") do
  org_cf.match?(/cloudflare_zero_trust_access_identity_provider[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "otp_idp_enabled local guards on cloudflare_account_id != null") do
  org_cf.match?(/otp_idp_enabled\s*=\s*var\.cloudflare_account_id\s*!=\s*null/)
end

expect(failures, "no terraform_data resource for otp provisioner (must use native resource)") do
  !org_cf.match?(/resource\s+"terraform_data"\s+"otp_identity_provider"/)
end

expect(failures, "no ensure-otp-idp.sh script reference (must use native resource)") do
  !org_cf.include?("ensure-otp-idp.sh")
end

expect(failures, "cloudflare_api_token variable removed from organization/variables.tf") do
  !org_vars.match?(/variable\s+"cloudflare_api_token"/)
end

expect(failures, "cloudflare provider version requires at least 5.16 in organization/terraform.tf") do
  org_tf.match?(/cloudflare\/cloudflare[\s\S]*?~>\s*5\.(?:1[6-9]|[2-9]\d)/m)
end

expect(failures, "no import block in module (import blocks are root-only; consumers handle import)") do
  !org_cf.match?(/^import\s*\{/m)
end

expect(failures, "no data source for identity providers in module (belongs in root consumer)") do
  !org_cf.match?(/data\s+"cloudflare_zero_trust_access_identity_providers"/)
end

if failures.empty?
  puts "tofu otp identity provider: OK"
else
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end
