resource "gitlab_project_variable" "telegram_bot_token" {
  count             = nonsensitive(var.alerting.telegram_bot_token != "") ? 1 : 0
  project           = var.ops_project_id
  key               = "TELEGRAM_BOT_TOKEN"
  value             = trimspace(var.alerting.telegram_bot_token)
  masked            = true
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "telegram_chat_id" {
  count             = nonsensitive(var.alerting.telegram_chat_id != "") ? 1 : 0
  project           = var.ops_project_id
  key               = "TELEGRAM_CHAT_ID"
  value             = trimspace(var.alerting.telegram_chat_id)
  masked            = true
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "uptime_monitor_enabled" {
  count             = nonsensitive(var.alerting.enable_uptime_monitor) ? 1 : 0
  project           = var.ops_project_id
  key               = "UPTIME_MONITOR_ENABLED"
  value             = "true"
  masked            = false
  protected         = true
  environment_scope = "production"
}
