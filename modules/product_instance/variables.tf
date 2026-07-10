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

variable "zone_id" {
  description = "Cloudflare zone ID of the product's apex domain. Gates the app DNS A record (A3): when set together with prod_host, creates an 'app' A record pointing to prod_host.ip, proxied. Defaults skip DNS resource creation."
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

variable "app_project_id" {
  description = "Numeric ID of the app project. Required when prod.enabled is true; used for the registry pull deploy token and app-project CI variables."
  type        = string
  default     = ""
}

variable "app_project_path" {
  description = "Full path of the app project (e.g. eiseron/afinados/afinados). Required when release_token is set or prod.enabled is true."
  type        = string
  default     = ""
}

variable "ops_project_path" {
  description = "Full path of the ops project (e.g. eiseron/afinados/afinados-ops). Required when prod.enabled is true; used as PROD_DEPLOYER_PROJECT in the app CI vars."
  type        = string
  default     = ""
}

variable "release_token" {
  description = "GitLab personal or project access token used by the release job to push tags and publish docs. When set, the module creates RELEASE_TOKEN and GITLAB_TOKEN (same value) as masked, protected CI variables on the app project (all environments). Defaults skip resource creation."
  type        = string
  default     = ""
  sensitive   = true
}

variable "group_id" {
  description = "Numeric ID of the product's GitLab group (e.g. the afinados group). Required when ci_vars tokens are set; group variables land here so every pipeline in the group inherits them without repeating the secret in each project."
  type        = string
  default     = ""
}

variable "ci_vars" {
  description = "Group-level and ops-project CI variables for the product's pipeline fleet. Tokens (github_token, gitlab_token, cloudflare_api_token) land as masked protected gitlab_group_variable on the product group. cloudflare_account_id lands as a non-masked protected group var. secrets_file lands as SECRETS_FILE on the ops project (production scope). All fields are optional; empty string skips resource creation for that variable."
  type = object({
    github_token          = optional(string, "")
    gitlab_token          = optional(string, "")
    cloudflare_api_token  = optional(string, "")
    cloudflare_account_id = optional(string, "")
    secrets_file          = optional(string, "")
  })
  default   = {}
  sensitive = true
}

variable "prod" {
  description = "Production deployment wiring. When enabled (and app_project_id is set) provisions: a pipeline trigger on the ops project (PROD_DEPLOYER_TRIGGER_TOKEN + PROD_DEPLOYER_PROJECT on the app project); a registry pull deploy token (KAMAL_REGISTRY_USERNAME + KAMAL_REGISTRY_PASSWORD on the ops project, production scope); a generated 64-char SECRET_KEY_BASE (ops project, production scope); PROD_PROJECT (ops project, production scope). Optionally passes R2 asset credentials as AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY on the app project when r2_access_key_id is set. When observability_otlp_endpoint is set it lands as OBSERVABILITY_OTLP_ENDPOINT (ops project, production scope, unmasked) so the app exports OTLP logs/traces to the co-located collector; the caller passes the concrete collector address (e.g. http://observability-collector:4318). Defaults skip all resource creation."
  type = object({
    enabled                     = optional(bool, false)
    r2_access_key_id            = optional(string, "")
    r2_secret_access_key        = optional(string, "")
    observability_otlp_endpoint = optional(string, "")
  })
  default   = {}
  sensitive = true
}

variable "backup" {
  description = "DB backup wiring. When bucket_name is set the module creates three protected CI variables on the ops project (PROD_BACKUP_BUCKET, PROD_BACKUP_NAME, PROD_BACKUP_AGE_RECIPIENTS) plus two pipeline schedules: a daily staleness verifier and a weekly restore drill. The drill schedule is activated only when drill_key is also set, and the key lands as a masked CI variable (PROD_BACKUP_DRILL_KEY). Defaults leave no resources created."
  type = object({
    bucket_name    = optional(string, "")
    name           = optional(string, "")
    age_recipients = optional(string, "")
    drill_key      = optional(string, "")
  })
  default   = {}
  sensitive = true
}

variable "prod_host" {
  description = "Pointer to the shared production server. When set, gates the app DNS A record (A3) and any resources that need the server address. Fields: ip is the server IPv4 used for the DNS record; ssh_pubkey is the host public key injected into known_hosts for SSH-based deployments. Null skips all prod_host-gated resources; apply succeeds without it."
  type = object({
    ip         = string
    ssh_pubkey = string
  })
  default = null
}

variable "r2_buckets" {
  description = "R2 bucket wiring for static assets and sourcemaps. cdn_domain gates assets bucket + CDN custom domain + write token + CI vars on the ops project (ASSETS_R2_BUCKET, ASSETS_R2_ENDPOINT, ASSETS_R2_ACCESS_KEY_ID, ASSETS_R2_SECRET_ACCESS_KEY, ASSETS_CDN_URL). sourcemaps_enabled adds a <slug>-sourcemaps bucket scoped into the same write token. zone_id is required for the CDN custom domain record; omitting it skips only the custom domain. assets_write_permission is the Cloudflare permission group ID for 'Workers R2 Storage Write' (resolved by the caller via cloudflare_api_token_permission_groups_list). r2_location is the Cloudflare R2 location hint. Empty cdn_domain skips all resource creation."
  type = object({
    cdn_domain              = optional(string, "")
    zone_id                 = optional(string, "")
    sourcemaps_enabled      = optional(bool, false)
    r2_location             = optional(string, "ENAM")
    assets_write_permission = optional(string, "")
  })
  default = {}
}

variable "site_preview" {
  description = "Static-site MR preview wiring (Cloudflare Pages, dispatch pattern). When site_project_id is set the module provisions, on ops_project_id, the deployer pipeline trigger and the PREVIEW_PAGES_PROJECT / PREVIEW_SITE_PROJECT dispatch variables, and on the site project the PREVIEW_DEPLOYER_PROJECT / PREVIEW_DEPLOYER_TRIGGER_TOKEN variables plus a job-token allowlist letting the site trigger the ops deployer. The Cloudflare token stays out of this module: it is account-scoped, minted where the account permission exists (eiseron-ops), and injected as a protected variable on the deployer. Defaults skip resource creation. Fields: site_project_id + site_project_path identify the static site repo; ops_project_path is the deployer path injected on the site; pages_project_name is the Cloudflare Pages project (the *.pages.dev host prefix)."
  type = object({
    site_project_id    = optional(string, "")
    site_project_path  = optional(string, "")
    ops_project_path   = optional(string, "")
    pages_project_name = optional(string, "")
  })
  default = {}
}

variable "runtime" {
  description = "App runtime-service wiring. When enable is true (and prod is enabled) the module stands up the product's runtime service, reusing the generated SECRET_KEY_BASE and building DATABASE_URL from db_tenant_password. The module owns the connection to the runtime host, so the consumer passes only data (never a provider). Dormant by default until the product cutover. Fields: host_ip and deploy_user are the production host address and SSH user the module connects to; app_host is the public host routed to the service; app_image is the image used only on create/recreate (the running image is owned by the deploy); observability_otlp_endpoint is where the app sends telemetry; admin_access_* wire the OIDC admin gate; placement_constraints select the host the app runs on."
  type = object({
    enable                      = optional(bool, false)
    host_ip                     = optional(string, "")
    deploy_user                 = optional(string, "deploy")
    app_host                    = optional(string, "")
    app_image                   = optional(string, "")
    observability_otlp_endpoint = optional(string, "http://observability-collector:4318")
    admin_access_issuer         = optional(string, "")
    admin_access_certs_url      = optional(string, "")
    admin_access_audiences      = optional(string, "")
    placement_constraints       = optional(list(string), ["node.role==manager"])
  })
  default = {}

  validation {
    condition     = !var.runtime.enable || (var.runtime.app_host != "" && var.runtime.app_image != "" && var.runtime.host_ip != "")
    error_message = "runtime.app_host, runtime.app_image and runtime.host_ip must be set when runtime.enable is true."
  }
}

variable "db_tenant_password" {
  description = "Password of the product's Postgres tenant role, used to assemble the app service DATABASE_URL (ecto://<slug>:<pw>@platform-db/<slug>_prod). Generated in the org ops repo and injected as TF_VAR_db_tenant_password only on production applies; empty while dormant."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = !var.runtime.enable || var.db_tenant_password != ""
    error_message = "db_tenant_password must be set when runtime.enable is true (an empty password yields a DATABASE_URL the app cannot authenticate with)."
  }
}

variable "repositories" {
  description = "All repositories managed for this product. Keyed by short name. Reserved keys 'app', 'site', and 'planning' trigger built-in wiring (prod/release/backup for app; preview pages for site; relaxed merge gates for planning); any other key creates an extra repo. Each entry creates a GitLab project in the product group and, if github is provided, a GitHub mirror. If pages is provided, a Cloudflare Pages project and domains are created."
  type = map(object({
    description       = optional(string, "")
    topics            = optional(list(string), [])
    visibility_level  = optional(string, "private")
    push_access_level = optional(string, "maintainer")
    pages = optional(object({
      production_branch = optional(string, "main")
      domains           = optional(list(string), [])
    }), null)
    github = optional(object({
      homepage_url = optional(string, "")
      has_projects = optional(bool, false)
    }), null)
  }))
  default = {}
}
