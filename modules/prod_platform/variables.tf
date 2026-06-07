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

variable "tang_thumbprint" {
  description = "Tang advertisement thumbprint (runtime artifact from the Tang server); not secret. Set after Tang is up."
  type        = string
  default     = "placeholder"
}
