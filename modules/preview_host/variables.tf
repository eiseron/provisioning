variable "name" {
  description = "Logical name for this preview host; used in resource names and Cloudflare tunnel name"
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx23"
}

variable "location" {
  description = "Hetzner Cloud datacenter location"
  type        = string
  default     = "fsn1"
}

variable "image" {
  description = "Hetzner Cloud image to provision"
  type        = string
  default     = "debian-13"
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hetzner; used by the provision job before cloudflared takes over"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the tunnel and the service token"
  type        = string
  sensitive   = true
}

variable "ssh_hostname" {
  description = "Hostname brokered by cloudflared for SSH (must fall under the wildcard zone gated by the Access app)"
  type        = string
}

variable "preview_domain_base" {
  description = "Apex domain for HTTP previews (e.g. preview.example.com). Slug joined with dash: <ref>-<base>. Single-level wildcard so Universal SSL covers it."
  type        = string
}

variable "service_token_duration" {
  description = "Validity period for the CI runner service token"
  type        = string
  default     = "8760h"
}
