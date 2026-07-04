# frozen_string_literal: true

BACKUP = File.expand_path("../../modules/product/backup.tf", __dir__)
VARS   = File.expand_path("../../modules/product/variables.tf", __dir__)

backup = File.read(BACKUP)
vars   = File.read(VARS)

failures = []
def expect(failures, description)
  failures << description unless yield
end

expect(failures, "enable_db_backup variable exists with default true") do
  vars.match?(/variable\s+"enable_db_backup"[\s\S]*?default\s*=\s*true/m)
end

expect(failures, "module db_backup_r2 is count-gated on enable_db_backup") do
  backup.match?(/module\s+"db_backup_r2"[\s\S]*?count\s*=\s*var\.enable_db_backup\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "backup_ci_vars local collapses to empty map when disabled") do
  backup.match?(/backup_ci_vars\s*=\s*var\.enable_db_backup\s*\?[\s\S]*?:\s*\{\}/)
end

expect(failures, "PROD_BACKUP_* vars use write credentials") do
  backup.match?(/PROD_BACKUP_AWS_ACCESS_KEY_ID[\s\S]*?write_access_key_id/) &&
    backup.match?(/PROD_BACKUP_AWS_SECRET_ACCESS_KEY[\s\S]*?write_secret_access_key/)
end

expect(failures, "PROD_DRILL_* vars use read credentials (not write)") do
  backup.match?(/PROD_DRILL_AWS_ACCESS_KEY_ID[\s\S]*?read_access_key_id/) &&
    backup.match?(/PROD_DRILL_AWS_SECRET_ACCESS_KEY[\s\S]*?read_secret_access_key/)
end

expect(failures, "PROD_DRILL_* does not use write credentials") do
  !backup.match?(/PROD_DRILL_AWS_ACCESS_KEY_ID[\s\S]*?write_access_key_id/)
end

expect(failures, "backup_ci_vars for_each targets ops_repo_key") do
  backup.match?(/module\.repository\[local\.ops_repo_key\]\.id/)
end

expect(failures, "backup_lock_prefix is count-gated on enable_db_backup") do
  backup.match?(/resource\s+"gitlab_project_variable"\s+"backup_lock_prefix"[\s\S]*?count\s*=\s*var\.enable_db_backup\s*\?\s*1\s*:\s*0/m)
end

expect(failures, "backup_ci_vars has no prevent_destroy") do
  !backup.match?(/resource\s+"gitlab_project_variable"\s+"backup_ci_vars"[\s\S]*?prevent_destroy\s*=\s*true/m)
end

expect(failures, "backup_lock_prefix has no prevent_destroy") do
  !backup.match?(/resource\s+"gitlab_project_variable"\s+"backup_lock_prefix"[\s\S]*?prevent_destroy\s*=\s*true/m)
end

if failures.empty?
  puts "All product db backup tests passed."
else
  failures.each { |f| puts "FAIL: #{f}" }
  exit 1
end
