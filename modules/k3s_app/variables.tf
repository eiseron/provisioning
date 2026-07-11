variable "enable" {
  description = "Create the app runtime service (Deployment + Service + IngressRoute + Secret + NetworkPolicy). Keep false so the module lands dormant until the cluster exists."
  type        = bool
  default     = false
}

variable "name" {
  description = "App/service name (the product slug); names the Deployment, Service and IngressRoute."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.name != ""
    error_message = "name must be set when enable = true."
  }
}

variable "namespace" {
  description = "Namespace the app runs in (the per-product namespace)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.namespace != ""
    error_message = "namespace must be set when enable = true."
  }
}

variable "image" {
  description = "App image used only on create/recreate (the running image is owned by the deploy via kubectl set image; the Deployment ignores changes to it). Source it from the current-release CI var."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.image != ""
    error_message = "image must be set when enable = true."
  }
}

variable "app_host" {
  description = "Primary public host the IngressRoute routes to this service."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.app_host != ""
    error_message = "app_host must be set when enable = true."
  }
}

variable "extra_hosts" {
  description = "Additional router hosts (e.g. the admin access host)."
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Container port the app listens on."
  type        = number
  default     = 4000
}

variable "replicas" {
  description = "Number of app replicas."
  type        = number
  default     = 1
}

variable "env_clear" {
  description = "Non-secret environment variables for the app container."
  type        = map(string)
  default     = {}
}

variable "env_secret" {
  description = "Secret environment variables (SECRET_KEY_BASE, DATABASE_URL, etc.), delivered as a Secret and injected via envFrom."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "node_selector" {
  description = "nodeSelector labels selecting which node the app runs on (the k8s equivalent of the swarm placement; e.g. { \"eiseron.com/product\" = \"afinados\" })."
  type        = map(string)
  default     = {}
}

variable "entrypoint" {
  description = "Traefik entrypoint the IngressRoute binds to."
  type        = string
  default     = "websecure"
}

variable "cert_resolver" {
  description = "Traefik ACME cert resolver name (matches the platform Traefik config)."
  type        = string
  default     = "cf"
}

variable "healthcheck_path" {
  description = "HTTP path for the readiness probe; only ready pods receive traffic (zero-downtime rollout)."
  type        = string
  default     = "/up"
}
