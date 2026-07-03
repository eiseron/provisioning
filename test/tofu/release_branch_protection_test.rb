# frozen_string_literal: true

REPO_MAIN = File.expand_path("../../modules/gitlab_repository_protected/main.tf", __dir__)
REPO_VARS = File.expand_path("../../modules/gitlab_repository_protected/variables.tf", __dir__)
ORG_MAIN  = File.expand_path("../../modules/organization/main.tf", __dir__)
ORG_VARS  = File.expand_path("../../modules/organization/variables.tf", __dir__)

repo_main = File.read(REPO_MAIN)
repo_vars = File.read(REPO_VARS)
org_main  = File.read(ORG_MAIN)
org_vars  = File.read(ORG_VARS)

failures = []
def expect(failures, description)
  failures << description unless yield
end

release_block = repo_main[/resource\s+"gitlab_branch_protection"\s+"release"\s*\{(.*?)\n\}/m, 1] || ""

expect(failures, "gitlab_branch_protection.release exists in gitlab_repository_protected") { !release_block.empty? }
expect(failures, "gitlab_branch_protection.release is count-guarded by protect_release_branch") do
  release_block.match?(/count\s*=\s*var\.protect_release_branch\s*\?\s*1\s*:\s*0/)
end
expect(failures, "gitlab_branch_protection.release protects the release/* pattern") do
  release_block.match?(/branch\s*=\s*"release\/\*"/)
end
expect(failures, "gitlab_branch_protection.release blocks push") do
  release_block.match?(/push_access_level\s*=\s*"no one"/)
end
expect(failures, "gitlab_branch_protection.release allows merge for maintainer only") do
  release_block.match?(/merge_access_level\s*=\s*"maintainer"/)
end
expect(failures, "gitlab_branch_protection.release disallows force push") do
  release_block.match?(/allow_force_push\s*=\s*false/)
end

expect(failures, "variable protect_release_branch exists in gitlab_repository_protected") do
  repo_vars.match?(/variable\s+"protect_release_branch"/)
end
expect(failures, "variable protect_release_branch defaults to false") do
  repo_vars.match?(/protect_release_branch[\s\S]*?default\s*=\s*false/m)
end

expect(failures, "repos type has optional protect_release_branch in organization") do
  org_vars.match?(/protect_release_branch\s*=\s*optional\(bool,\s*false\)/)
end

expect(failures, "module repo passes protect_release_branch in organization") do
  org_main.match?(/protect_release_branch\s*=\s*each\.value\.protect_release_branch/)
end

expect(failures, "eiseron-site has protect_release_branch = true in default_repos") do
  site_block = org_main[/-site\"\s*=\s*\{(.*?)\n\s*\}/m, 1] || ""
  site_block.match?(/protect_release_branch\s*=\s*true/)
end

expect(failures, "eiseron-planning has protect_release_branch = true in default_repos") do
  planning_block = org_main[/-planning\"\s*=\s*\{(.*?)\n\s*\}/m, 1] || ""
  planning_block.match?(/protect_release_branch\s*=\s*true/)
end

expect(failures, "eiseron-ops has protect_release_branch = false (keeps map type uniform)") do
  ops_block = org_main[/-ops\"\s*=\s*\{(.*?)\n\s*\}/m, 1] || ""
  ops_block.match?(/protect_release_branch\s*=\s*false/)
end

if failures.empty?
  puts "tofu release branch protection: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
