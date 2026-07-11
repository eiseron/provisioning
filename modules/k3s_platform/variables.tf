variable "enable" {
  description = "Configure the k3s platform layer (Traefik ACME + platform namespace). Keep false so the module lands dormant until the cluster exists."
  type        = bool
  default     = false
}

variable "acme_email" {
  description = "Let's Encrypt account email for the Traefik ACME resolver."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.acme_email != ""
    error_message = "acme_email must be set when enable = true."
  }
}

variable "acme_domains" {
  description = "Apex domains to request wildcard certificates for (main + *.domain via DNS-01)."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable || length(var.acme_domains) > 0
    error_message = "acme_domains must be non-empty when enable = true."
  }
}

variable "cloudflare_dns_api_token" {
  description = "Cloudflare API token used for the Traefik ACME DNS-01 challenge, stored as a Kubernetes secret Traefik reads via CF_DNS_API_TOKEN."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable || var.cloudflare_dns_api_token != ""
    error_message = "cloudflare_dns_api_token must be set when enable = true."
  }
}

variable "acme_use_staging" {
  description = "Use the Let's Encrypt staging CA (avoids rate limits while validating)."
  type        = bool
  default     = false
}

variable "platform_namespace" {
  description = "Namespace for shared platform workloads."
  type        = string
  default     = "platform"
}

variable "acme_storage_size" {
  description = "Size of the PVC backing Traefik's acme.json (local-path, on the encrypted volume)."
  type        = string
  default     = "128Mi"
}
