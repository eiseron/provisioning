variable "enable" {
  description = "Create the swarm ingress stack (overlay networks + Traefik service). Keep false so the module lands dormant until the cutover."
  type        = bool
  default     = false
}

variable "traefik_image" {
  description = "Traefik image, digest-pinned like every other stack image (lock.yml overrides this in prod). A bare tag causes a perpetual diff because the provider resolves it to a digest."
  type        = string
  default     = "traefik:3.7@sha256:6608e0f4b12983a2e9874f5dac86105bd449b59067b6806350a030216aebf393"
}

variable "traefik_network_name" {
  description = "Overlay network Traefik discovers services on; app services attach to it to be routed."
  type        = string
  default     = "traefik"
}

variable "internal_network_name" {
  description = "Overlay network for service-to-service traffic that must not be reachable from the edge (e.g. app to postgres)."
  type        = string
  default     = "internal"
}

variable "acme_email" {
  description = "Let's Encrypt account email for ACME certificate issuance."
  type        = string
  default     = ""
}

variable "acme_domains" {
  description = "Apex domains to request wildcard certificates for (main + *.domain via DNS-01)."
  type        = list(string)
  default     = []
}

variable "acme_cf_dns_api_token" {
  description = "Cloudflare API token used for the ACME DNS-01 challenge. Stored as a swarm secret, never inlined into the Traefik config."
  type        = string
  default     = ""
  sensitive   = true
}

variable "acme_use_staging" {
  description = "Use the Let's Encrypt staging CA (avoids rate limits while validating)."
  type        = bool
  default     = false
}

variable "acme_volume_name" {
  description = "Named Docker volume that persists acme.json on the manager node. Managed by Terraform so no host directory needs to pre-exist."
  type        = string
  default     = "traefik-acme"
}

variable "log_level" {
  description = "Traefik log level."
  type        = string
  default     = "INFO"
}

variable "placement_constraints" {
  description = "Swarm placement constraints for Traefik; it needs the docker socket of a manager node to read the swarm provider."
  type        = list(string)
  default     = ["node.role==manager"]
}
