# frozen_string_literal: true

ORG_GH   = File.expand_path("../../modules/organization/github.tf", __dir__)
ORG_VARS = File.expand_path("../../modules/organization/variables.tf", __dir__)
ORG_TF   = File.expand_path("../../modules/organization/terraform.tf", __dir__)

org_gh   = File.read(ORG_GH)
org_vars = File.read(ORG_VARS)
org_tf   = File.read(ORG_TF)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "module github_repo exists in organization/github.tf") do
  org_gh.match?(/module\s+"github_repo"/)
end

expect(failures, "module github_repo uses for_each over var.github_repos") do
  org_gh.match?(/for_each\s*=\s*var\.github_repos/)
end

expect(failures, "module github_repo sources ../github_repository_protected") do
  org_gh.match?(%r{source\s*=\s*"\.\.\/github_repository_protected"})
end

expect(failures, "module github_repo passes name = each.key") do
  org_gh.match?(/name\s*=\s*each\.key/)
end

expect(failures, "module github_repo passes description") do
  org_gh.match?(/description\s*=\s*each\.value\.description/)
end

expect(failures, "module github_repo passes enable_branch_protection") do
  org_gh.match?(/enable_branch_protection\s*=\s*each\.value\.enable_branch_protection/)
end

expect(failures, "variable github_repos exists in organization/variables.tf") do
  org_vars.match?(/variable\s+"github_repos"/)
end

expect(failures, "variable github_repos defaults to empty map") do
  org_vars.match?(/github_repos[\s\S]*?default\s*=\s*\{\}/m)
end

expect(failures, "github_repos type has optional description") do
  org_vars.match?(/description\s*=\s*optional\(string/)
end

expect(failures, "github_repos type has optional topics") do
  org_vars.match?(/topics\s*=\s*optional\(list\(string\)/)
end

expect(failures, "github_repos type has optional enable_branch_protection") do
  org_vars.match?(/enable_branch_protection\s*=\s*optional\(bool/)
end

expect(failures, "github_repos variable has key format validation") do
  org_vars.match?(/github_repos[\s\S]*?validation/m)
end

expect(failures, "github provider declared in organization/terraform.tf") do
  org_tf.match?(/integrations\/github/)
end

if failures.empty?
  puts "tofu github repos phase 5: OK"
else
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end
