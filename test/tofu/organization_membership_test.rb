# frozen_string_literal: true

MAIN = File.expand_path("../../modules/organization/main.tf", __dir__)
VARS = File.expand_path("../../modules/organization/variables.tf", __dir__)
source = File.read(MAIN)
vars   = File.read(VARS)

failures = []
def expect(failures, description)
  failures << description unless yield
end

robot_mb  = source[/resource\s+"gitlab_group_membership"\s+"robot"\s*\{(.*?)\n\}/m, 1] || ""
robot_sa  = source[/resource\s+"gitlab_group_service_account"\s+"robot"\s*\{(.*?)\n\}/m, 1] || ""
sa_mb     = source[/resource\s+"gitlab_group_membership"\s+"service_account"\s*\{(.*?)\n\}/m, 1] || ""

expect(failures, "gitlab_group_membership.robot existe") { !robot_mb.empty? }
expect(failures, "gitlab_group_membership.robot e count-guardado por robot_user_id") do
  robot_mb.match?(/count\s*=\s*var\.robot_user_id\s*!=\s*null\s*\?\s*1\s*:\s*0/)
end
expect(failures, "gitlab_group_membership.robot tem access_level developer") do
  robot_mb.match?(/access_level\s*=\s*"developer"/)
end
expect(failures, "gitlab_group_membership.robot tem prevent_destroy") do
  robot_mb.match?(/prevent_destroy\s*=\s*true/)
end

expect(failures, "gitlab_group_service_account.robot existe") { !robot_sa.empty? }
expect(failures, "gitlab_group_service_account.robot e count-guardado por service_account") do
  robot_sa.match?(/count\s*=\s*var\.service_account\s*!=\s*null\s*\?\s*1\s*:\s*0/)
end
expect(failures, "gitlab_group_service_account.robot tem prevent_destroy") do
  robot_sa.match?(/prevent_destroy\s*=\s*true/)
end

expect(failures, "gitlab_group_membership.service_account existe") { !sa_mb.empty? }
expect(failures, "gitlab_group_membership.service_account e count-guardado por service_account") do
  sa_mb.match?(/count\s*=\s*var\.service_account\s*!=\s*null\s*\?\s*1\s*:\s*0/)
end
expect(failures, "gitlab_group_membership.service_account tem access_level developer") do
  sa_mb.match?(/access_level\s*=\s*"developer"/)
end
expect(failures, "gitlab_group_membership.service_account tem prevent_destroy") do
  sa_mb.match?(/prevent_destroy\s*=\s*true/)
end
expect(failures, "gitlab_group_membership.service_account usa service_account_id do SA") do
  sa_mb.match?(/gitlab_group_service_account\.robot\[0\]\.service_account_id/)
end

expect(failures, "variavel robot_user_id tem validacao de positivo") do
  vars.match?(/robot_user_id.*?validation.*?robot_user_id\s*>\s*0/m)
end
expect(failures, "variavel service_account tem validacao de strings nao-vazias") do
  vars.match?(/service_account.*?validation.*?(trimspace|length)/m)
end

if failures.empty?
  puts "tofu organization membership: OK"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
