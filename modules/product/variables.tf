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

variable "additional_preview_access_policies" {
  description = "Extra Cloudflare Zero Trust Access policies to attach to the preview application alongside the email-domain policy this module creates. Each entry is the id of a policy declared by the caller (typically a non_identity service-token policy for the deploy healthcheck)."
  type        = list(string)
  default     = []
}

variable "admin_gate_email_domains" {
  description = "Email domains allowed through Cloudflare Access on the app's /admin path; gates <app_host>/admin for the team. Required (non-empty) when the admin gate is enabled; the consumer supplies its own domains."
  type        = list(string)
  default     = []
}

variable "admin_gate_auth_domain" {
  description = "Zero Trust team auth domain (e.g. team.cloudflareaccess.com) used to build ADMIN_ACCESS_ISSUER and ADMIN_ACCESS_CERTS_URL. Required when the admin gate is enabled."
  type        = string
  default     = null
}

variable "admin_gate_app_host" {
  description = "Host that serves the app's /admin routes (e.g. app.<domain>). When set, the module gates <app_host>/admin with a Cloudflare Access application and provisions the ADMIN_ACCESS_* CI vars on the ops repo; the gate rides on the app's existing origin and certificate. Null skips the admin gate."
  type        = string
  default     = null
}

variable "media_subdomain" {
  description = "Subdomain label for the public R2 media bucket that serves uploaded images (e.g. img -> img.<domain>). When set, the module provisions the <slug>-media R2 bucket, its public custom domain, an R2 write token, and the MEDIA_* CI vars on the ops repo. Null skips media uploads."
  type        = string
  default     = null
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

variable "enable_db_backup" {
  description = "When true, provisions an R2 backup bucket (via db_backup_r2) and writes PROD_BACKUP_* and PROD_DRILL_* CI variables into the ops repo."
  type        = bool
  default     = true
}

variable "db_backup_immutable_days" {
  description = "Days each backup object stays immutable via R2 Object Lock. Forwarded to db_backup_r2; only relevant when enable_db_backup = true."
  type        = number
  default     = 7
}

variable "db_backup_gem_retention_days" {
  description = "Mirror of the gem's PROD_BACKUP_RETENTION_DAYS. Must exceed db_backup_immutable_days. Only relevant when enable_db_backup = true."
  type        = number
  default     = 15
}

