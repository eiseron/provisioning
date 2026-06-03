variable "name" {
  description = "Logical name; used in the Cloudflare tunnel and service-token names"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the tunnel and the service token"
  type        = string
  sensitive   = true
}

variable "ssh_hostname" {
  description = "Hostname brokered by cloudflared for SSH (must fall under a zone gated by an Access app)"
  type        = string
}

variable "preview_domain_base" {
  description = "Apex domain for HTTP previews; the tunnel routes *.<preview_domain_base> to traefik on the host"
  type        = string
}

variable "service_token_duration" {
  description = "Validity period for the CI runner Access service token"
  type        = string
  default     = "8760h"
}
