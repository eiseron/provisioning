variable "enable" {
  description = "Provision the error monitoring DNS record and deploy variables. Keep false until ready to deploy the service."
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
  description = "Subdomain of the error monitoring dashboard under the zone."
  type        = string
  default     = "errors"
}

variable "prod_host_ip" {
  description = "IPv4 of the production host error monitoring is co-located on."
  type        = string
}

variable "ops_project_id" {
  description = "GitLab project whose CI runs the error monitoring deploy; receives the deploy variables."
  type        = string
}

variable "secret_key_epoch" {
  description = "Rotation epoch for ERROR_MONITORING_SECRET_KEY; bump to regenerate on the next apply."
  type        = string
  default     = "1"
}

variable "db_password_epoch" {
  description = "Rotation epoch for the error monitoring database role password; bump to regenerate on the next apply."
  type        = string
  default     = "1"
}
