variable "name" {
  description = "Logical name / hostname for the production host; used in the Hostinger resource names"
  type        = string
}

variable "plan" {
  description = "Hostinger VPS plan identifier"
  type        = string
}

variable "data_center_id" {
  description = "Hostinger data center (region) ID; configurable per deployment"
  type        = number
}

variable "template_id" {
  description = "Hostinger OS template ID. Defaults to the newest Debian template (resolved by name via the hostinger_vps_templates data source) when null."
  type        = number
  default     = null
  nullable    = true
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hostinger; used by the provision job for direct root SSH"
  type        = string
}
