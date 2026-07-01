variable "enable" {
  description = "Provision the GlitchTip DNS record and deploy variables. Keep false until ready to deploy the service."
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Cloudflare zone that hosts the dashboard subdomain (e.g. the eiseron.com zone)."
  type        = string
}

variable "zone_domain" {
  description = "Apex domain of the zone; the dashboard host is <subdomain>.<zone_domain>."
  type        = string
}

variable "subdomain" {
  description = "Subdomain of the GlitchTip dashboard under the zone."
  type        = string
  default     = "errors"
}

variable "prod_host_ip" {
  description = "IPv4 of the production host GlitchTip is co-located on."
  type        = string
}

variable "ops_project_id" {
  description = "GitLab project whose CI runs the GlitchTip deploy; receives the deploy variables."
  type        = string
}

variable "image" {
  description = "Pinned GlitchTip image reference."
  type        = string
  default     = "glitchtip/glitchtip:6.2.0"
}

variable "secret_key_epoch" {
  description = "Rotation epoch for GLITCHTIP_SECRET_KEY; bump to regenerate on the next apply."
  type        = string
  default     = "1"
}

variable "db_password_epoch" {
  description = "Rotation epoch for the glitchtip database role password; bump to regenerate on the next apply."
  type        = string
  default     = "1"
}
