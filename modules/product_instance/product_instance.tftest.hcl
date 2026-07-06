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

run "prod_disabled_by_default" {
  command = plan

  assert {
    condition     = length(gitlab_pipeline_trigger.prod_deployer) == 0
    error_message = "No prod_deployer trigger must be created when prod is not enabled"
  }

  assert {
    condition     = length(gitlab_project_deploy_token.prod_registry) == 0
    error_message = "No prod_registry deploy token must be created when prod is not enabled"
  }

  assert {
    condition     = length(gitlab_project_variable.prod_ops) == 0
    error_message = "No prod ops CI vars must be created when prod is not enabled"
  }
}

run "prod_enabled_creates_trigger_token_and_deploy_token" {
  command = plan

  variables {
    app_project_id   = "87654321"
    app_project_path = "eiseron/myproduct/myproduct"
    ops_project_path = "eiseron/myproduct/myproduct-ops"
    prod             = { enabled = true }
  }

  assert {
    condition     = length(gitlab_pipeline_trigger.prod_deployer) == 1
    error_message = "prod_deployer trigger must be created when prod.enabled is true"
  }

  assert {
    condition     = gitlab_pipeline_trigger.prod_deployer[0].project == var.ops_project_id
    error_message = "prod_deployer trigger must be on the ops project"
  }

  assert {
    condition     = length(gitlab_project_deploy_token.prod_registry) == 1
    error_message = "prod_registry deploy token must be created when prod.enabled is true"
  }

  assert {
    condition     = gitlab_project_deploy_token.prod_registry[0].project == "87654321"
    error_message = "prod_registry deploy token must be on the app project"
  }

  assert {
    condition     = length(gitlab_project_variable.prod_ops) == 4
    error_message = "Four prod ops CI vars must be created (KAMAL_REGISTRY_USERNAME, KAMAL_REGISTRY_PASSWORD, SECRET_KEY_BASE, PROD_PROJECT)"
  }

  assert {
    condition     = gitlab_project_variable.prod_ops["SECRET_KEY_BASE"].masked == true
    error_message = "SECRET_KEY_BASE must be masked"
  }

  assert {
    condition     = gitlab_project_variable.prod_ops["KAMAL_REGISTRY_PASSWORD"].masked == true
    error_message = "KAMAL_REGISTRY_PASSWORD must be masked"
  }

  assert {
    condition     = length(gitlab_project_variable.prod_app) == 2
    error_message = "Two prod app CI vars must be created without R2 (PROD_DEPLOYER_TRIGGER_TOKEN, PROD_DEPLOYER_PROJECT)"
  }
}

run "prod_with_r2_creates_four_app_vars" {
  command = plan

  variables {
    app_project_id   = "87654321"
    app_project_path = "eiseron/myproduct/myproduct"
    ops_project_path = "eiseron/myproduct/myproduct-ops"
    prod = {
      enabled              = true
      r2_access_key_id     = "r2-key-id"
      r2_secret_access_key = "r2-secret"
    }
  }

  assert {
    condition     = length(gitlab_project_variable.prod_app) == 4
    error_message = "Four prod app CI vars must be created with R2 (PROD_DEPLOYER_TRIGGER_TOKEN, PROD_DEPLOYER_PROJECT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
  }

  assert {
    condition     = contains(keys(gitlab_project_variable.prod_app), "AWS_ACCESS_KEY_ID")
    error_message = "AWS_ACCESS_KEY_ID must be present when r2_access_key_id is set"
  }

  assert {
    condition     = gitlab_project_variable.prod_app["AWS_SECRET_ACCESS_KEY"].masked == true
    error_message = "AWS_SECRET_ACCESS_KEY must be masked"
  }
}

run "prod_host_null_by_default" {
  command = plan

  assert {
    condition     = var.prod_host == null
    error_message = "prod_host must default to null"
  }
}

run "prod_host_pointer_accepted" {
  command = plan

  variables {
    prod_host = {
      ip         = "1.2.3.4"
      ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    }
  }

  assert {
    condition     = var.prod_host.ip == "1.2.3.4"
    error_message = "prod_host.ip must reflect the provided value"
  }
}

run "prod_host_ssh_pubkey_accepted" {
  command = plan

  variables {
    prod_host = {
      ip         = "1.2.3.4"
      ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    }
  }

  assert {
    condition     = var.prod_host.ssh_pubkey == "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    error_message = "prod_host.ssh_pubkey must reflect the provided value"
  }
}

run "r2_assets_disabled_by_default" {
  command = plan

  assert {
    condition     = length(cloudflare_r2_bucket.assets) == 0
    error_message = "No assets bucket must be created when r2_buckets.cdn_domain is empty"
  }
}

run "r2_assets_creates_bucket_when_cdn_domain_set" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = length(cloudflare_r2_bucket.assets) == 1
    error_message = "Assets bucket must be created when cdn_domain is set"
  }
}

run "r2_assets_bucket_name_uses_slug" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = cloudflare_r2_bucket.assets[0].name == "test-product-assets"
    error_message = "Assets bucket name must be <slug>-assets"
  }
}

run "r2_sourcemaps_disabled_by_default" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = length(cloudflare_r2_bucket.sourcemaps) == 0
    error_message = "No sourcemaps bucket must be created when sourcemaps_enabled is false"
  }
}

run "r2_sourcemaps_creates_bucket" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      sourcemaps_enabled      = true
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = length(cloudflare_r2_bucket.sourcemaps) == 1
    error_message = "Sourcemaps bucket must be created when sourcemaps_enabled is true"
  }
}

run "r2_assets_ci_vars_are_masked" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = gitlab_project_variable.assets_ops["ASSETS_R2_ACCESS_KEY_ID"].masked == true
    error_message = "ASSETS_R2_ACCESS_KEY_ID must be masked"
  }
}

run "r2_assets_secret_key_is_masked" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = gitlab_project_variable.assets_ops["ASSETS_R2_SECRET_ACCESS_KEY"].masked == true
    error_message = "ASSETS_R2_SECRET_ACCESS_KEY must be masked"
  }
}

run "r2_cdn_skipped_without_zone_id" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = length(cloudflare_r2_custom_domain.cdn) == 0
    error_message = "CDN custom domain must not be created when zone_id is empty"
  }
}

run "r2_cdn_created_with_zone_id" {
  command = plan

  variables {
    r2_buckets = {
      cdn_domain              = "cdn.myproduct.io"
      zone_id                 = "abc123zone"
      assets_write_permission = "a1b2c3d4e5f6"
    }
  }

  assert {
    condition     = length(cloudflare_r2_custom_domain.cdn) == 1
    error_message = "CDN custom domain must be created when zone_id is set"
  }
}

run "app_dns_disabled_by_default" {
  command = plan

  assert {
    condition     = length(cloudflare_dns_record.app) == 0
    error_message = "No app DNS record must be created when prod_host and zone_id are not set"
  }
}

run "app_dns_requires_prod_host" {
  command = plan

  variables {
    zone_id = "abc123zone"
  }

  assert {
    condition     = length(cloudflare_dns_record.app) == 0
    error_message = "No app DNS record must be created when prod_host is null"
  }
}

run "app_dns_created_with_prod_host_and_zone" {
  command = plan

  variables {
    zone_id = "abc123zone"
    prod_host = {
      ip         = "1.2.3.4"
      ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    }
  }

  assert {
    condition     = length(cloudflare_dns_record.app) == 1
    error_message = "App DNS record must be created when prod_host and zone_id are set"
  }
}

run "app_dns_content_matches_prod_host_ip" {
  command = plan

  variables {
    zone_id = "abc123zone"
    prod_host = {
      ip         = "1.2.3.4"
      ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    }
  }

  assert {
    condition     = cloudflare_dns_record.app[0].content == "1.2.3.4"
    error_message = "App DNS record content must match prod_host.ip"
  }
}

run "app_dns_is_proxied" {
  command = plan

  variables {
    zone_id = "abc123zone"
    prod_host = {
      ip         = "1.2.3.4"
      ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAItest"
    }
  }

  assert {
    condition     = cloudflare_dns_record.app[0].proxied == true
    error_message = "App DNS record must be proxied through Cloudflare"
  }
}
