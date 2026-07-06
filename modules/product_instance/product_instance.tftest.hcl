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

run "release_token_disabled_by_default" {
  command = plan

  assert {
    condition     = length(gitlab_project_variable.release_token) == 0
    error_message = "No release_token CI var must be created when release_token is not set"
  }

  assert {
    condition     = length(gitlab_project_variable.gitlab_token_docs) == 0
    error_message = "No GITLAB_TOKEN CI var must be created when release_token is not set"
  }
}

run "release_token_creates_two_vars_on_app_project" {
  command = plan

  variables {
    app_project_path = "eiseron/myproduct/myproduct"
    release_token    = "glpat-secret-token"
  }

  assert {
    condition     = length(gitlab_project_variable.release_token) == 1
    error_message = "RELEASE_TOKEN CI var must be created when release_token is set"
  }

  assert {
    condition     = gitlab_project_variable.release_token[0].project == "eiseron/myproduct/myproduct"
    error_message = "RELEASE_TOKEN must be created on the app project"
  }

  assert {
    condition     = gitlab_project_variable.release_token[0].masked == true
    error_message = "RELEASE_TOKEN must be masked"
  }

  assert {
    condition     = length(gitlab_project_variable.gitlab_token_docs) == 1
    error_message = "GITLAB_TOKEN CI var must be created when release_token is set"
  }

  assert {
    condition     = gitlab_project_variable.gitlab_token_docs[0].masked == true
    error_message = "GITLAB_TOKEN must be masked"
  }
}

run "ci_vars_disabled_by_default" {
  command = plan

  assert {
    condition     = length(gitlab_group_variable.ci_token) == 0
    error_message = "No group CI token vars must be created when ci_vars is empty"
  }

  assert {
    condition     = length(gitlab_group_variable.cloudflare_account_id) == 0
    error_message = "No CLOUDFLARE_ACCOUNT_ID group var must be created when ci_vars is empty"
  }

  assert {
    condition     = length(gitlab_project_variable.secrets_file) == 0
    error_message = "No SECRETS_FILE var must be created when ci_vars.secrets_file is empty"
  }
}

run "ci_vars_creates_group_and_project_vars" {
  command = plan

  variables {
    group_id = "99887766"
    ci_vars = {
      github_token          = "ghp_secret"
      gitlab_token          = "glpat_secret"
      cloudflare_api_token  = "cf_secret"
      cloudflare_account_id = "abc123"
      secrets_file          = "secrets.enc.env"
    }
  }

  assert {
    condition     = length(gitlab_group_variable.ci_token) == 3
    error_message = "Three masked group vars must be created (GITHUB_TOKEN, GITLAB_TOKEN, CLOUDFLARE_API_TOKEN)"
  }

  assert {
    condition     = contains(keys(gitlab_group_variable.ci_token), "GITHUB_TOKEN")
    error_message = "GITHUB_TOKEN group var must be present"
  }

  assert {
    condition     = gitlab_group_variable.ci_token["GITHUB_TOKEN"].masked == true
    error_message = "GITHUB_TOKEN must be masked"
  }

  assert {
    condition     = length(gitlab_group_variable.cloudflare_account_id) == 1
    error_message = "CLOUDFLARE_ACCOUNT_ID group var must be created"
  }

  assert {
    condition     = gitlab_group_variable.cloudflare_account_id[0].masked == false
    error_message = "CLOUDFLARE_ACCOUNT_ID must not be masked"
  }

  assert {
    condition     = length(gitlab_project_variable.secrets_file) == 1
    error_message = "SECRETS_FILE project var must be created on ops project"
  }
}
