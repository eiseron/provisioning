locals {
  backup_enabled         = nonsensitive(var.backup.bucket_name != "")
  drill_enabled          = local.backup_enabled && nonsensitive(var.backup.drill_key != "")
  backup_cronjob_enabled = local.backup_enabled && local.k3s_enabled

  backup_ci_vars = local.backup_enabled ? {
    PROD_BACKUP_BUCKET         = var.backup.bucket_name
    PROD_BACKUP_NAME           = var.slug
    PROD_BACKUP_AGE_RECIPIENTS = var.backup.age_recipients
  } : {}

  backup_gem_runtime_image = "registry.gitlab.com/eiseron/stack/public-image-bases/gem-runtime@sha256:d20433ca616fd03204cb8ff712d8a99a154752fc6aef1a14a2e09c408c98c70f"
}

data "gitlab_project_variable" "backup_r2_access_key_id" {
  count = local.backup_cronjob_enabled ? 1 : 0

  project           = var.ops_project_id
  key               = "PROD_BACKUP_AWS_ACCESS_KEY_ID"
  environment_scope = "production"
}

data "gitlab_project_variable" "backup_r2_secret_access_key" {
  count = local.backup_cronjob_enabled ? 1 : 0

  project           = var.ops_project_id
  key               = "PROD_BACKUP_AWS_SECRET_ACCESS_KEY"
  environment_scope = "production"
}

resource "kubernetes_cron_job_v1" "db_backup" {
  count = local.backup_cronjob_enabled ? 1 : 0

  metadata {
    name      = "${var.slug}-db-backup"
    namespace = local.k3s_namespace
  }

  spec {
    schedule                      = var.backup_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {}
      spec {
        backoff_limit = 0

        template {
          metadata {}
          spec {
            restart_policy = "Never"

            container {
              name    = "backup"
              image   = local.backup_gem_runtime_image
              command = ["eiseron", "db", "backup"]

              env {
                name  = "PGHOST"
                value = "platform-db-rw.platform"
              }
              env {
                name  = "PGUSER"
                value = var.slug
              }
              env {
                name  = "PROD_BACKUP_DATABASE"
                value = "${var.slug}_prod"
              }
              env {
                name  = "PROD_BACKUP_NAME"
                value = var.slug
              }
              env {
                name  = "PROD_BACKUP_BUCKET"
                value = var.backup.bucket_name
              }
              env {
                name  = "PROD_BACKUP_AGE_RECIPIENTS"
                value = var.backup.age_recipients
              }
              env {
                name  = "CLOUDFLARE_ACCOUNT_ID"
                value = var.cloudflare_account_id
              }
              env {
                name  = "PGPASSWORD"
                value = var.db_tenant_password
              }
              env {
                name  = "AWS_ACCESS_KEY_ID"
                value = data.gitlab_project_variable.backup_r2_access_key_id[0].value
              }
              env {
                name  = "AWS_SECRET_ACCESS_KEY"
                value = data.gitlab_project_variable.backup_r2_secret_access_key[0].value
              }
            }
          }
        }
      }
    }
  }
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
  ref         = "refs/heads/production"
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
  ref         = "refs/heads/production"
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
