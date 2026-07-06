locals {
  backup_enabled = nonsensitive(var.backup.bucket_name != "")
  drill_enabled  = local.backup_enabled && nonsensitive(var.backup.drill_key != "")

  backup_ci_vars = local.backup_enabled ? {
    PROD_BACKUP_BUCKET         = var.backup.bucket_name
    PROD_BACKUP_NAME           = var.backup.name
    PROD_BACKUP_AGE_RECIPIENTS = var.backup.age_recipients
  } : {}
}

resource "gitlab_project_variable" "backup" {
  for_each          = local.backup_ci_vars
  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = false
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "backup_drill_key" {
  count             = local.drill_enabled ? 1 : 0
  project           = var.ops_project_id
  key               = "PROD_BACKUP_DRILL_KEY"
  value             = trimspace(var.backup.drill_key)
  masked            = true
  protected         = true
  environment_scope = "production"
}

resource "gitlab_pipeline_schedule" "backup_verify" {
  count       = local.backup_enabled ? 1 : 0
  project     = var.ops_project_id
  description = "Daily backup-staleness verifier (fails if the newest backup is older than PROD_BACKUP_STALE_HOURS)"
  ref         = "refs/heads/main"
  cron        = "0 11 * * *"
  active      = true
}

resource "gitlab_pipeline_schedule_variable" "backup_verify_job" {
  count                = local.backup_enabled ? 1 : 0
  project              = var.ops_project_id
  pipeline_schedule_id = gitlab_pipeline_schedule.backup_verify[0].pipeline_schedule_id
  key                  = "BACKUP_JOB"
  value                = "verify"
}

resource "gitlab_pipeline_schedule" "backup_drill" {
  count       = local.backup_enabled ? 1 : 0
  project     = var.ops_project_id
  description = "Weekly DB restore drill (verifies the latest backup restores and the drill key decrypts)"
  ref         = "refs/heads/main"
  cron        = "0 5 * * 1"
  active      = local.drill_enabled
}

resource "gitlab_pipeline_schedule_variable" "backup_drill_job" {
  count                = local.backup_enabled ? 1 : 0
  project              = var.ops_project_id
  pipeline_schedule_id = gitlab_pipeline_schedule.backup_drill[0].pipeline_schedule_id
  key                  = "BACKUP_JOB"
  value                = "drill"
}
