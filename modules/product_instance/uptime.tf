data "gitlab_repository_file" "uptime_worker_js" {
  count     = nonsensitive(var.alerting.enable_uptime_monitor) ? 1 : 0
  project   = "eiseron/stack/workers"
  ref       = var.workers_ref
  file_path = "workers/uptime.js"
}

resource "cloudflare_workers_kv_namespace" "uptime_history" {
  count      = nonsensitive(var.alerting.enable_uptime_monitor) ? 1 : 0
  account_id = var.cloudflare_account_id
  title      = "${var.slug}-uptime-history"
}

resource "cloudflare_workers_script" "uptime" {
  count       = nonsensitive(var.alerting.enable_uptime_monitor) ? 1 : 0
  account_id  = var.cloudflare_account_id
  script_name = "${var.slug}-uptime"
  content     = base64decode(data.gitlab_repository_file.uptime_worker_js[0].content)
  main_module = "uptime.js"

  bindings = [
    {
      name         = "HISTORY"
      type         = "kv_namespace"
      namespace_id = cloudflare_workers_kv_namespace.uptime_history[0].id
    },
    {
      name = "HEALTHCHECK_URL"
      type = "secret_text"
      text = var.healthcheck_url
    },
    {
      name = "TELEGRAM_BOT_TOKEN"
      type = "secret_text"
      text = var.alerting.telegram_bot_token
    },
    {
      name = "TELEGRAM_CHAT_ID"
      type = "secret_text"
      text = var.alerting.telegram_chat_id
    },
  ]
}

resource "cloudflare_workers_cron_trigger" "uptime" {
  count       = nonsensitive(var.alerting.enable_uptime_monitor) ? 1 : 0
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_workers_script.uptime[0].script_name

  schedules = [
    { cron = "*/1 * * * *" },
  ]
}
