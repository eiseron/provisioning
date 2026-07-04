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
