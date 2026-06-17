variable "ops_project_id" {
  description = "ID of the <slug>-ops project that owns the runtime configuration (CI variables, schedules, deploy tokens). The module writes every resource against this project."
  type        = string
}

variable "alerting" {
  description = "Per-product alerting configuration. The Telegram bot is the single delivery channel for every CI alerter the product uses (db-backup-verify, terraform-drift, and the uptime monitor when enabled). Fields: telegram_bot_token + telegram_chat_id wire the bot (created per-product via @BotFather on bootstrap, value lives in the product's sops); enable_uptime_monitor turns on the external uptime probe surface — when true the module injects UPTIME_MONITOR_ENABLED=true at production scope (the runtime resources — Cloudflare Worker compiled from the gem to WASM, KV for history, Pages with the CNAME for status.<domain> — land here under the same flag once the gem ships the deploy command, planning#85). All defaults skip resource creation: apply succeeds and notify-telegram's after_script exits early silently."
  type = object({
    telegram_bot_token    = optional(string, "")
    telegram_chat_id      = optional(string, "")
    enable_uptime_monitor = optional(bool, false)
  })
  default   = {}
  sensitive = true
}
