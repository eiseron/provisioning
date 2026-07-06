variables {
  ops_project_id = "12345678"
  slug           = "test-product"

  cloudflare_account_id = "b406da57022f7381e45749bddbee7f8a"
  healthcheck_url       = "https://app.example.com/up"
  workers_ref           = "v0.4.0"

  alerting = {
    telegram_bot_token    = "test-bot-token"
    telegram_chat_id      = "test-chat-id"
    enable_uptime_monitor = true
  }
}

run "uptime_cron_is_five_minutes" {
  command = plan

  assert {
    condition     = cloudflare_workers_cron_trigger.uptime[0].schedules[0].cron == "*/5 * * * *"
    error_message = "Uptime cron must be */5 * * * * (every 5 minutes)"
  }
}

run "uptime_monitor_disabled_creates_no_resources" {
  command = plan

  variables {
    alerting = {
      enable_uptime_monitor = false
    }
  }

  assert {
    condition     = length(cloudflare_workers_cron_trigger.uptime) == 0
    error_message = "No cron trigger must be created when uptime monitor is disabled"
  }

  assert {
    condition     = length(cloudflare_workers_kv_namespace.uptime_history) == 0
    error_message = "No KV namespace must be created when uptime monitor is disabled"
  }
}

run "backup_disabled_by_default_creates_no_resources" {
  command = plan

  assert {
    condition     = length(gitlab_project_variable.backup) == 0
    error_message = "No backup CI vars must be created when backup is not configured"
  }

  assert {
    condition     = length(gitlab_pipeline_schedule.backup_verify) == 0
    error_message = "No backup_verify schedule must be created when backup is not configured"
  }

  assert {
    condition     = length(gitlab_pipeline_schedule.backup_drill) == 0
    error_message = "No backup_drill schedule must be created when backup is not configured"
  }
}

run "backup_enabled_creates_ci_vars_and_schedules" {
  command = plan

  variables {
    backup = {
      bucket_name    = "my-backups"
      name           = "myproduct"
      age_recipients = "age1abc123"
      drill_key      = ""
    }
  }

  assert {
    condition     = length(gitlab_project_variable.backup) == 3
    error_message = "Three backup CI vars must be created (PROD_BACKUP_BUCKET, PROD_BACKUP_NAME, PROD_BACKUP_AGE_RECIPIENTS)"
  }

  assert {
    condition     = gitlab_project_variable.backup["PROD_BACKUP_BUCKET"].masked == false
    error_message = "PROD_BACKUP_BUCKET must not be masked"
  }

  assert {
    condition     = length(gitlab_pipeline_schedule.backup_verify) == 1
    error_message = "backup_verify schedule must be created when backup is enabled"
  }

  assert {
    condition     = gitlab_pipeline_schedule.backup_verify[0].cron == "0 11 * * *"
    error_message = "backup_verify must run daily at 11:00 UTC"
  }

  assert {
    condition     = length(gitlab_project_variable.backup_drill_key) == 0
    error_message = "No drill key CI var must be created when drill_key is empty"
  }

  assert {
    condition     = gitlab_pipeline_schedule.backup_drill[0].active == false
    error_message = "backup_drill schedule must be inactive when drill_key is empty"
  }
}

run "backup_drill_key_activates_drill_schedule" {
  command = plan

  variables {
    backup = {
      bucket_name    = "my-backups"
      name           = "myproduct"
      age_recipients = "age1abc123"
      drill_key      = "secret-drill-key"
    }
  }

  assert {
    condition     = length(gitlab_project_variable.backup_drill_key) == 1
    error_message = "Drill key CI var must be created when drill_key is set"
  }

  assert {
    condition     = gitlab_pipeline_schedule.backup_drill[0].active == true
    error_message = "backup_drill schedule must be active when drill_key is set"
  }
}
