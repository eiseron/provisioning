# frozen_string_literal: true

ORG_CF   = File.expand_path("../../modules/organization/cloudflare.tf", __dir__)
ORG_VARS = File.expand_path("../../modules/organization/variables.tf", __dir__)
ORG_TF   = File.expand_path("../../modules/organization/terraform.tf", __dir__)
ORG_OUT  = File.expand_path("../../modules/organization/outputs.tf", __dir__)

org_cf   = File.read(ORG_CF)
org_vars = File.read(ORG_VARS)
org_tf   = File.read(ORG_TF)
org_out  = File.read(ORG_OUT)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "cloudflare_pages_project.site exists in organization/cloudflare.tf") do
  org_cf.match?(/resource\s+"cloudflare_pages_project"\s+"site"/)
end

expect(failures, "cloudflare_pages_project.site is count-guarded by site_pages_enabled") do
  org_cf.match?(/count\s*=\s*local\.site_pages_enabled\s*\?\s*1\s*:\s*0/)
end

expect(failures, "cloudflare_pages_project.site uses var.site_preview.pages_project_name as name") do
  org_cf.match?(/name\s*=\s*var\.site_preview\.pages_project_name/)
end

expect(failures, "cloudflare_pages_project.site has prevent_destroy lifecycle") do
  org_cf.match?(/cloudflare_pages_project[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "cloudflare_pages_domain.site exists in organization/cloudflare.tf") do
  org_cf.match?(/resource\s+"cloudflare_pages_domain"\s+"site"/)
end

expect(failures, "cloudflare_pages_domain.site uses for_each over var.site_domains") do
  org_cf.match?(/for_each\s*=.*toset\(var\.site_domains\)/)
end

expect(failures, "site_pages_enabled local guards on cloudflare_account_id != null") do
  org_cf.match?(/var\.cloudflare_account_id\s*!=\s*null/)
end

expect(failures, "site_pages_enabled local guards on site_preview_enabled") do
  org_cf.match?(/local\.site_preview_enabled/)
end

expect(failures, "site_pages_enabled local guards against empty pages_project_name") do
  org_cf.match?(/var\.site_preview\.pages_project_name\s*!=\s*""/)
end

expect(failures, "cloudflare_pages_domain.site has prevent_destroy lifecycle") do
  org_cf.match?(/cloudflare_pages_domain[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "variable cloudflare_account_id exists in organization/variables.tf") do
  org_vars.match?(/variable\s+"cloudflare_account_id"/)
end

expect(failures, "variable cloudflare_account_id defaults to null") do
  org_vars.match?(/cloudflare_account_id[\s\S]*?default\s*=\s*null/m)
end

expect(failures, "variable cloudflare_account_id rejects empty string via validation") do
  org_vars.match?(/cloudflare_account_id[\s\S]*?validation[\s\S]*?length\(trimspace\(var\.cloudflare_account_id\)/m)
end

expect(failures, "variable site_domains exists in organization/variables.tf") do
  org_vars.match?(/variable\s+"site_domains"/)
end

expect(failures, "variable site_domains defaults to empty list") do
  org_vars.match?(/site_domains[\s\S]*?default\s*=\s*\[\]/m)
end

expect(failures, "variable site_domains rejects blank entries via validation") do
  org_vars.match?(/site_domains[\s\S]*?validation[\s\S]*?length\(trimspace\(d\)/m)
end

expect(failures, "cloudflare provider declared in organization/terraform.tf") do
  org_tf.match?(/cloudflare\/cloudflare/)
end

expect(failures, "cloudflare provider version requires at least 5.16") do
  org_tf.match?(/cloudflare\/cloudflare[\s\S]*?~>\s*5\.(?:1[6-9]|[2-9]\d)/m)
end

expect(failures, "output site_pages_project_name exists in organization/outputs.tf") do
  org_out.match?(/output\s+"site_pages_project_name"/)
end

if failures.empty?
  puts "tofu cloudflare pages phase 4: OK"
else
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end
