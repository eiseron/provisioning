variable "enable" {
  description = "Create the app service. Keep false so the module lands dormant until the product cutover."
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Swarm service name and Traefik router/service key (the product slug, e.g. afinados)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.service_name != ""
    error_message = "service_name must be set when enable = true."
  }
}

variable "app_image" {
  description = "App image used only on create/recreate (the running image is owned by the deploy via docker service update; the service ignores_changes on it). Source it from the current-release CI var so a recreate comes back on the deployed version."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.app_image != ""
    error_message = "app_image must be set when enable = true."
  }
}

variable "app_port" {
  description = "Container port the app listens on."
  type        = number
  default     = 4000
}

variable "app_host" {
  description = "Primary public host Traefik routes to this service."
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

variable "traefik_network_id" {
  description = "ID of the Traefik overlay network (by ID to avoid the perpetual-diff forced replacement)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.traefik_network_id != ""
    error_message = "traefik_network_id must be set when enable = true."
  }
}

variable "traefik_network_name" {
  description = "Name of the Traefik overlay network (Traefik swarm provider routes over it)."
  type        = string
  default     = "traefik"
}

variable "internal_network_id" {
  description = "ID of the internal overlay network the app reaches Postgres on (by ID)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.internal_network_id != ""
    error_message = "internal_network_id must be set when enable = true."
  }
}

variable "env_clear" {
  description = "Non-secret environment variables for the app container."
  type        = map(string)
  default     = {}
}

variable "env_secret" {
  description = "Secret environment variables (SECRET_KEY_BASE, DATABASE_URL, etc.), merged into the container env like the Kamal deploy does."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "replicas" {
  description = "Number of app replicas (1 matches the Kamal web role)."
  type        = number
  default     = 1
}

variable "healthcheck_test" {
  description = "Container healthcheck command that gates the start-first rollover (the swarm equivalent of the kamal-proxy healthcheck). Release-specific; empty relies on replicas >= 2 for zero-downtime."
  type        = list(string)
  default     = []
}

variable "healthcheck_interval" {
  description = "Container healthcheck interval."
  type        = string
  default     = "10s"
}

variable "healthcheck_timeout" {
  description = "Container healthcheck timeout."
  type        = string
  default     = "5s"
}

variable "healthcheck_retries" {
  description = "Container healthcheck retries before unhealthy."
  type        = number
  default     = 5
}

variable "healthcheck_start_period" {
  description = "Grace period before healthcheck failures count (app boot time)."
  type        = string
  default     = "30s"
}

variable "healthcheck_path" {
  description = "HTTP path Traefik uses for its loadbalancer healthcheck (only healthy tasks receive traffic)."
  type        = string
  default     = "/up"
}

variable "entrypoint" {
  description = "Traefik entrypoint the router binds to."
  type        = string
  default     = "websecure"
}

variable "placement_constraints" {
  description = "Swarm placement constraints for the app service."
  type        = list(string)
  default     = ["node.role==manager"]
}
