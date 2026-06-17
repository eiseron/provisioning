variable "slug" {
  description = "Product slug (the subgroup path, the app repo name, the tenant name)."
  type        = string
}

variable "description" {
  description = "Human description of the product."
  type        = string
  default     = ""
}

variable "parent_group_id" {
  description = "ID of the top-level GitLab group that owns the subgroup and the service account."
  type        = string
}

variable "visibility" {
  description = "Default visibility for the product subgroup and app repo. Private by default; public is opt-in."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.visibility)
    error_message = "visibility must be private or public."
  }
}

variable "domain" {
  description = "Apex domain for the product's Cloudflare zone (e.g. example.com)."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the zone, R2 bucket and tokens."
  type        = string
}

variable "apex_target" {
  description = "Optional IPv4 for an A record on the apex (proxied). Null skips it."
  type        = string
  default     = null
}

variable "preview_host_ip" {
  description = "Optional IPv4 of the shared preview host. When set, the module wires the wildcard DNS and the preview handoff into the ops repo. Null skips preview."
  type        = string
  default     = null
}

variable "preview_mix_env" {
  description = "MIX_ENV the preview image is built and run with; a dedicated :preview env, standardized across products."
  type        = string
  default     = "preview"
}

variable "preview_access_email_domains" {
  description = "Email domains allowed through Cloudflare Access on every preview; gates *-preview.<domain> so dev routes and the app are not public. Required (non-empty) when preview is enabled; the consumer supplies its own domains."
  type        = list(string)
  default     = []
}

variable "repositories" {
  description = "Extra repos beyond the app and the ops repo, keyed by repo name."
  type = map(object({
    description = optional(string, "")
    public      = optional(bool, false)
    mirror      = optional(bool)
    topics      = optional(list(string), [])
    is_ops      = optional(bool, false)
  }))
  default = {}
}

variable "topics" {
  description = "Topics for the app repo."
  type        = list(string)
  default     = []
}

variable "avatar_path" {
  description = "Optional avatar image path passed to the repository module."
  type        = string
  default     = null
}

variable "r2_location" {
  description = "Cloudflare R2 location hint for the state bucket."
  type        = string
  default     = "ENAM"
}

variable "github_owner" {
  description = "GitHub owner for the push mirror of public repos."
  type        = string
  default     = "eiseron"
}

variable "github_mirror_token" {
  description = "GitHub token embedded in the push-mirror URL. Required only when a repo is mirrored."
  type        = string
  default     = null
  sensitive   = true
}

variable "alerting" {
  description = "Per-product alerting configuration. The Telegram bot is the single delivery channel for every CI alerter the product uses (db-backup-verify, terraform-drift, and the uptime monitor when enabled). Fields: telegram_bot_token + telegram_chat_id wire the bot (created per-product via @BotFather on bootstrap, value lives in the product's sops); enable_uptime_monitor turns on the external uptime probe surface — when true the module injects UPTIME_MONITOR_ENABLED=true into <slug>-ops at production scope (the runtime resources — Cloudflare Worker compiled from the gem to WASM, KV for history, Pages with the CNAME for status.<domain> — land here under the same flag once the gem ships the deploy command, planning#85). All defaults skip resource creation: apply succeeds and notify-telegram's after_script exits early silently."
  type = object({
    telegram_bot_token    = optional(string, "")
    telegram_chat_id      = optional(string, "")
    enable_uptime_monitor = optional(bool, false)
  })
  default   = {}
  sensitive = true
}



