# frozen_string_literal: true

ADMIN = File.expand_path("../../modules/product/admin_access.tf", __dir__)
VARS  = File.expand_path("../../modules/product/variables.tf", __dir__)
OUT   = File.expand_path("../../modules/product/outputs.tf", __dir__)

admin = File.read(ADMIN)
vars  = File.read(VARS)
out   = File.read(OUT)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "admin_gate_enabled local guards on admin_gate_origin_ip != null") do
  admin.match?(/admin_gate_enabled\s*=\s*var\.admin_gate_origin_ip\s*!=\s*null/)
end

expect(failures, "access policy admin is count-guarded by admin_gate_enabled") do
  admin.match?(/resource\s+"cloudflare_zero_trust_access_policy"\s+"admin"[\s\S]*?count\s*=\s*local\.admin_gate_enabled\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "access policy admin has no auth_method require (it blocks One-time PIN login; OTP is the only IdP so the requirement is redundant)") do
  !admin.match?(/auth_method/)
end

expect(failures, "access policy admin includes team email domains from admin_gate_email_domains") do
  admin.match?(/include\s*=\s*\[for\s+domain\s+in\s+var\.admin_gate_email_domains[\s\S]*?email_domain\s*=\s*\{\s*domain\s*=\s*domain/m)
end

expect(failures, "access policy admin has prevent_destroy") do
  admin.match?(/access_policy"\s+"admin"[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "access policy admin preconditions on non-empty email domains") do
  admin.match?(/length\(var\.admin_gate_email_domains\)\s*>\s*0/)
end

expect(failures, "access policy admin preconditions on auth_domain present") do
  admin.match?(/var\.admin_gate_auth_domain\s*!=\s*null/)
end

expect(failures, "access application admin is count-guarded by admin_gate_enabled") do
  admin.match?(/resource\s+"cloudflare_zero_trust_access_application"\s+"admin"[\s\S]*?count\s*=\s*local\.admin_gate_enabled\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "access application admin does not auto-redirect to identity") do
  admin.match?(/auto_redirect_to_identity\s*=\s*false/)
end

expect(failures, "access application admin session duration is 24h (matches the working team apps)") do
  admin.match?(/session_duration\s*=\s*"24h"/)
end

expect(failures, "access application admin gates the app host /admin path (rides on the app origin/cert)") do
  admin.match?(/admin_gate_uri\s*=\s*"\$\{var\.admin_gate_app_host\}\/admin"/) &&
    admin.match?(/uri\s*=\s*local\.admin_gate_uri/)
end

expect(failures, "access policy admin preconditions on app host present") do
  admin.match?(/var\.admin_gate_app_host\s*!=\s*null/)
end

expect(failures, "variable admin_gate_app_host exists") do
  vars.match?(/variable\s+"admin_gate_app_host"/)
end

expect(failures, "access application admin has prevent_destroy") do
  admin.match?(/access_application"\s+"admin"[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "admin DNS record is count-guarded and proxied to the origin ip") do
  admin.match?(/resource\s+"cloudflare_dns_record"\s+"admin"[\s\S]*?content\s*=\s*var\.admin_gate_origin_ip[\s\S]*?proxied\s*=\s*true/m)
end

expect(failures, "ADMIN_ACCESS ops CI vars are provisioned") do
  admin.match?(/ADMIN_ACCESS_AUDIENCES/) && admin.match?(/ADMIN_ACCESS_ISSUER/) && admin.match?(/ADMIN_ACCESS_CERTS_URL/)
end

expect(failures, "aud is read via one() rather than indexed") do
  admin.match?(/one\(cloudflare_zero_trust_access_application\.admin\[\*\]\.aud\)/) &&
    !admin.match?(/access_application\.admin\[0\]\.aud/)
end

expect(failures, "variable admin_gate_origin_ip defaults to null") do
  vars.match?(/variable\s+"admin_gate_origin_ip"[\s\S]*?default\s*=\s*null/m)
end

expect(failures, "variable admin_gate_origin_ip validates an IPv4 or null") do
  vars.match?(/admin_gate_origin_ip[\s\S]*?validation[\s\S]*?regex/m)
end

expect(failures, "variable admin_gate_email_domains exists") do
  vars.match?(/variable\s+"admin_gate_email_domains"/)
end

expect(failures, "variable admin_gate_auth_domain exists") do
  vars.match?(/variable\s+"admin_gate_auth_domain"/)
end

expect(failures, "variable admin_gate_subdomain defaults to admin") do
  vars.match?(/variable\s+"admin_gate_subdomain"[\s\S]*?default\s*=\s*"admin"/m)
end

expect(failures, "output admin_access_aud exists") do
  out.match?(/output\s+"admin_access_aud"/)
end

if failures.empty?
  puts "tofu admin gate: OK"
else
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end
