variable "enable" {
  description = "Provision the production host. Keep false until the Hostinger token and plan/data_center/template IDs are available, so the consuming apply stays green meanwhile."
  type        = bool
  default     = false

  validation {
    condition = !var.enable || (
      var.hostinger_token != null &&
      var.plan != null &&
      var.data_center_id != null &&
      var.template_id != null
    )
    error_message = "enable requires hostinger_token, plan, data_center_id and template_id to be set first."
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

variable "plan" {
  description = "Hostinger VPS plan identifier"
  type        = string
  default     = null
  nullable    = true
}

variable "data_center_id" {
  description = "Hostinger data center (region) ID; configurable per residency requirement"
  type        = number
  default     = null
  nullable    = true
}

variable "template_id" {
  description = "Hostinger OS template ID (Debian)"
  type        = number
  default     = null
  nullable    = true
}

variable "hostinger_token" {
  description = "Hostinger API token, used only to assert it is present before enabling. The provider itself is configured by the caller."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
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
