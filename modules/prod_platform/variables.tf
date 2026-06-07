variable "enable" {
  description = "Provision the production host. Keep false until plan and region/data_center are set (and the Hostinger token is in the apply SOPS). The token is NOT checked here: it is null on read-only plans by design, and the provider fails clearly at apply if it is truly missing."
  type        = bool
  default     = false

  validation {
    condition = !var.enable || (
      var.plan != null &&
      (var.region != null || var.data_center_id != null)
    )
    error_message = "enable requires plan and region (or data_center_id) to be set first (template_id defaults to Debian)."
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

variable "region" {
  description = "Human region string (e.g. \"Brazil\") resolved to the Hostinger data center; configurable per residency requirement"
  type        = string
  default     = null
  nullable    = true
}

variable "data_center_id" {
  description = "Hostinger data center ID. Optional override; when null it is resolved from var.region."
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
