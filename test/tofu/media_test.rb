# frozen_string_literal: true

MEDIA = File.expand_path("../../modules/product/media.tf", __dir__)
VARS  = File.expand_path("../../modules/product/variables.tf", __dir__)

media = File.read(MEDIA)
vars  = File.read(VARS)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "media_enabled local guards on media_subdomain != null") do
  media.match?(/media_enabled\s*=\s*var\.media_subdomain\s*!=\s*null/)
end

expect(failures, "media R2 bucket is named <slug>-media and count-guarded") do
  media.match?(/media_bucket\s*=\s*"\$\{var\.slug\}-media"/) &&
    media.match?(/resource\s+"cloudflare_r2_bucket"\s+"media"[\s\S]*?count\s*=\s*local\.media_enabled\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "media R2 bucket has prevent_destroy") do
  media.match?(/cloudflare_r2_bucket"\s+"media"[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "media is served by a public R2 custom domain on <media_subdomain>.<domain>") do
  media.match?(/resource\s+"cloudflare_r2_custom_domain"\s+"media"[\s\S]*?domain\s*=\s*local\.media_host[\s\S]*?enabled\s*=\s*true/m)
end

expect(failures, "media write token is scoped to the media bucket only (least privilege)") do
  media.match?(/resource\s+"cloudflare_api_token"\s+"media_write"[\s\S]*?Workers R2 Storage Write[\s\S]*?cloudflare_r2_bucket\.media\[0\]\.name/m)
end

expect(failures, "the R2 S3 secret is the sha256 of the token value (Cloudflare R2 derivation)") do
  media.match?(/MEDIA_R2_SECRET_ACCESS_KEY[\s\S]*?sha256\(one\(cloudflare_api_token\.media_write\[\*\]\.value\)\)/m)
end

expect(failures, "the R2 S3 access key id is the token id") do
  media.match?(/MEDIA_R2_ACCESS_KEY_ID[\s\S]*?one\(cloudflare_api_token\.media_write\[\*\]\.id\)/m)
end

expect(failures, "credentials are masked and the public base url is exposed to the ops repo") do
  media.match?(/MEDIA_R2_SECRET_ACCESS_KEY[\s\S]*?masked\s*=\s*true/m) &&
    media.match?(/MEDIA_PUBLIC_BASE_URL[\s\S]*?value\s*=\s*"https:\/\/\$\{local\.media_host\}"/m)
end

expect(failures, "media ops CI vars are provisioned on the ops repo, protected, production-scoped") do
  media.match?(/resource\s+"gitlab_project_variable"\s+"media_ops"[\s\S]*?module\.repository\[local\.ops_repo_key\][\s\S]*?protected\s*=\s*true/m)
end

expect(failures, "variable media_subdomain defaults to null") do
  vars.match?(/variable\s+"media_subdomain"[\s\S]*?default\s*=\s*null/m)
end

if failures.empty?
  puts "tofu media: OK"
else
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end
