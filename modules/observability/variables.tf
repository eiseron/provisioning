variable "enable" {
  description = "Provision the observability backend (R2 bucket, DNS record and deploy variables). Keep false until ready to deploy the service."
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Cloudflare zone that hosts the dashboard subdomain (e.g. the example.com zone)."
  type        = string
}

variable "zone_domain" {
  description = "Apex domain of the zone; the dashboard host is <subdomain>.<zone_domain>."
  type        = string
}

variable "subdomain" {
  description = "Subdomain of the observability dashboard under the zone."
  type        = string
  default     = "observe"
}

variable "prod_host_ip" {
  description = "IPv4 of the production host the observability backend is co-located on."
  type        = string
}

variable "ops_project_id" {
  description = "GitLab project whose CI runs the observability deploy; receives the deploy variables."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account that owns the R2 bucket backing OpenObserve storage."
  type        = string
}

variable "r2_location" {
  description = "R2 location hint for the observability bucket (e.g. enam, weur). Empty lets Cloudflare choose."
  type        = string
  default     = ""
}

variable "root_email" {
  description = "Bootstrap root user email for OpenObserve. Consumer-supplied (kept out of the generic manifest)."
  type        = string
  default     = ""
}

variable "root_password_epoch" {
  description = "Rotation epoch for the OpenObserve root password; bump to regenerate on the next apply."
  type        = string
  default     = "1"
}

variable "smtp_password" {
  description = "SMTP app password enabling OpenObserve password recovery and alert email. Empty disables outbound email."
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp" {
  description = "Non-secret SMTP connection settings the consumer supplies (kept out of the generic manifest). Only consumed when smtp_password is set."
  type = object({
    user = optional(string, "")
    host = optional(string, "")
    port = optional(string, "587")
    from = optional(string, "")
  })
  default = {}
}
