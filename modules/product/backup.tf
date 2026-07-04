module "db_backup_r2" {
  count  = var.enable_db_backup ? 1 : 0
  source = "../db_backup_r2"

  slug                  = var.slug
  cloudflare_account_id = var.cloudflare_account_id
  r2_location           = var.r2_location
  backup_immutable_days = var.db_backup_immutable_days
  gem_retention_days    = var.db_backup_gem_retention_days
}

locals {
  backup_ci_vars = var.enable_db_backup ? {
    PROD_BACKUP_AWS_ACCESS_KEY_ID     = { value = module.db_backup_r2[0].write_access_key_id, masked = true }
    PROD_BACKUP_AWS_SECRET_ACCESS_KEY = { value = module.db_backup_r2[0].write_secret_access_key, masked = true }
    PROD_DRILL_AWS_ACCESS_KEY_ID      = { value = module.db_backup_r2[0].read_access_key_id, masked = true }
    PROD_DRILL_AWS_SECRET_ACCESS_KEY  = { value = module.db_backup_r2[0].read_secret_access_key, masked = true }
  } : {}
}

resource "gitlab_project_variable" "backup_ci_vars" {
  for_each          = local.backup_ci_vars
  project           = module.repository[local.ops_repo_key].id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "backup_lock_prefix" {
  count             = var.enable_db_backup ? 1 : 0
  project           = module.repository[local.ops_repo_key].id
  key               = "PROD_BACKUP_LOCK_PREFIX"
  value             = module.db_backup_r2[0].lock_prefix
  masked            = false
  protected         = true
  environment_scope = "production"
}
