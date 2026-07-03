variable "enable" {
  description = "Provision the production host (Hetzner). Keep false until location is set."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable || var.location != null
    error_message = "enable requires location to be set (e.g. ash, fsn1)."
  }
}

variable "name" {
  description = "Logical name / hostname for the production host"
  type        = string
  default     = "prod"
}

variable "ops_project_id" {
  description = "GitLab project ID where the org-level production CI variables are created (the *-ops pipeline that provisions the host)"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type for the production host"
  type        = string
  default     = "cpx21"
}

variable "location" {
  description = "Hetzner location for the production host (e.g. ash, fsn1); configurable per deployment"
  type        = string
  default     = null
  nullable    = true
}

variable "image" {
  description = "Hetzner image for the production host"
  type        = string
  default     = "debian-13"
}

variable "key_server_thumbprint" {
  description = "Encryption key server (Tang) advertisement thumbprint — a runtime artifact generated when the key server first starts; not secret. Set it once the key server is up."
  type        = string
  default     = "placeholder"
}

variable "encrypt_db" {
  description = "Encrypt the production databases at rest. When true, provisions the dedicated Tang host (Hetzner) and the prod host's pg_luks (LUKS data root). Defaults to true (secure by default); set false only when no database needs encryption (then no Tang host, no cost). WARNING: only safe to disable BEFORE any host is encrypted — once a host has LUKS, turning this off destroys the Tang key server and bricks the next boot; follow the decommission procedure first (see README / eiseron-planning#45)."
  type        = bool
  default     = true
}

variable "key_server_type" {
  description = "Hetzner server type for the encryption key server (Tang) host (cheapest cax11 by default; it serves only a tiny HTTP advertisement)"
  type        = string
  default     = "cax11"
}

variable "key_server_location" {
  description = "Hetzner location for the encryption key server (Tang) host"
  type        = string
  default     = "nbg1"
}

variable "error_monitoring_enable" {
  description = "Provision the co-located error monitoring service (DNS record + deploy variables) on the prod host. Requires enable."
  type        = bool
  default     = false
}

variable "error_monitoring_smtp_password" {
  description = "SMTP app password for the error monitoring service outbound email. Empty leaves email on the console backend."
  type        = string
  default     = ""
  sensitive   = true
}

variable "error_monitoring_smtp" {
  description = "Non-secret SMTP settings (user/host/port/from) for the error monitoring service. Consumed only when error_monitoring_smtp_password is set."
  type = object({
    user = optional(string, "")
    host = optional(string, "")
    port = optional(string, "587")
    from = optional(string, "")
  })
  default = {}
}

variable "zone_id" {
  description = "Cloudflare zone id that hosts the error monitoring / observability dashboard subdomains. Consumed when error_monitoring_enable or observability_enable."
  type        = string
  default     = ""
}

variable "zone_domain" {
  description = "Apex domain of the Cloudflare zone; the error monitoring dashboard is errors.<zone_domain> and observability is observe.<zone_domain>. Consumed when error_monitoring_enable or observability_enable."
  type        = string
  default     = ""
}

variable "observability_enable" {
  description = "Provision the co-located observability backend (OpenObserve + R2 bucket + OTel collector deploy variables) on the prod host. Requires enable."
  type        = bool
  default     = false
}

variable "observability_root_email" {
  description = "Bootstrap root user email for OpenObserve. Consumer-supplied; only consumed when observability_enable."
  type        = string
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare account that owns the observability R2 bucket. Only consumed when observability_enable."
  type        = string
  default     = ""
}

variable "r2_location" {
  description = "R2 location hint for the observability bucket (e.g. enam, weur). Empty lets Cloudflare choose. Only consumed when observability_enable."
  type        = string
  default     = ""
}

variable "observability_smtp_password" {
  description = "SMTP app password for OpenObserve password recovery and alert email. Empty disables outbound email. Only consumed when observability_enable."
  type        = string
  default     = ""
  sensitive   = true
}

variable "observability_smtp" {
  description = "Non-secret SMTP settings (user/host/port/from) for OpenObserve. Consumed only when observability_smtp_password is set."
  type = object({
    user = optional(string, "")
    host = optional(string, "")
    port = optional(string, "587")
    from = optional(string, "")
  })
  default = {}
}

variable "observability_root_password" {
  description = "Explicit OpenObserve root password (consumer-chosen, from SOPS) so a human can log in. Empty uses the generated random password. Only consumed when observability_enable."
  type        = string
  default     = ""
  sensitive   = true
}
