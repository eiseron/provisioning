variable "ops_project_id" {
  description = "ID of the <slug>-ops project that owns the runtime configuration (CI variables, schedules, deploy tokens). The module writes every resource against this project."
  type        = string
}

variable "alerting" {
  description = "Per-product alerting configuration. The Telegram bot is the single delivery channel for every CI alerter the product uses (db-backup-verify, terraform-drift, and the uptime monitor when enabled). The two secrets land as masked + protected gitlab_project_variable on the ops project (production scope) so that any job extending notify-telegram.yml can reach them without having to decrypt the product's sops file; that pattern keeps blast radius small (only TELEGRAM_BOT_TOKEN leaks if a runner is compromised on this job, not the rest of sops). Fields: telegram_bot_token + telegram_chat_id wire the bot (created per-product via @BotFather on bootstrap, value lives in the product's sops as TF_VAR_telegram_*); enable_uptime_monitor turns on the external uptime probe surface — when true the module also provisions the Cloudflare Worker that pings healthcheck_url on a 1-minute cron and posts to Telegram on every state change, plus the KV namespace it uses for the previous status. Defaults skip resource creation: apply succeeds and notify-telegram's after_script exits early silently."
  type = object({
    telegram_bot_token    = optional(string, "")
    telegram_chat_id      = optional(string, "")
    enable_uptime_monitor = optional(bool, false)
  })
  default   = {}
  sensitive = true
}

variable "slug" {
  description = "Product slug. Used to derive the Cloudflare Worker name (<slug>-uptime) when the uptime probe is enabled."
  type        = string
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID. Required when alerting.enable_uptime_monitor is true; the worker, KV namespace and cron trigger land in this account."
  type        = string
  default     = ""
}

variable "healthcheck_url" {
  description = "Full URL the uptime probe fetches (e.g. https://app.<domain>/up). Required when alerting.enable_uptime_monitor is true."
  type        = string
  sensitive   = true
  default     = ""
}

variable "workers_ref" {
  description = "Git tag of eiseron/stack/workers the uptime worker is pinned to (e.g. v0.1.0). Required when alerting.enable_uptime_monitor is true."
  type        = string
  default     = ""
}
