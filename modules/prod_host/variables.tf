variable "name" {
  description = "Logical name / hostname for the production host; used in the Hostinger resource names"
  type        = string
}

variable "plan" {
  description = "Hostinger VPS plan identifier"
  type        = string
}

variable "region" {
  description = "Human region string matched against the Hostinger data center name/city/location/continent (e.g. \"Brazil\") to resolve data_center_id. Used only when data_center_id is null."
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
  description = "Hostinger OS template ID. Defaults to the newest Debian template (resolved by name via the hostinger_vps_templates data source) when null."
  type        = number
  default     = null
  nullable    = true
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hostinger; used by the provision job for direct root SSH"
  type        = string
}
