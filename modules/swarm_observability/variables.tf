variable "enable" {
  description = "Create the observability stack (OpenObserve + otel-collector + host/container/postgres exporters). Keep false so the module lands dormant until the cutover."
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Swarm service name for OpenObserve; also the stable DNS name the collector and app send OTLP to (replaces the Kamal observability-web-<sha> container name)."
  type        = string
  default     = "observability"
}

variable "observability_image" {
  description = "OpenObserve image, digest-pinned via lock.yml in prod (the internally built platform image has no public digest to default to, so it is required when enabled)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.observability_image != ""
    error_message = "observability_image must be set when enable = true."
  }
}

variable "collector_image" {
  description = "OpenTelemetry Collector Contrib image, digest-pinned to match the Kamal accessory. A bare tag causes a perpetual diff."
  type        = string
  default     = "otel/opentelemetry-collector-contrib@sha256:4935caa35e9a4cb387e35732e8fb22b2b5759af8d12e7043357f03837f6e8df5"
}

variable "node_exporter_image" {
  description = "Prometheus node-exporter image, digest-pinned to match the Kamal accessory."
  type        = string
  default     = "prom/node-exporter@sha256:e9cff4fc67b1818f8c97adb115b9f12c9a54b533de86765d4a0effc01b357205"
}

variable "cadvisor_image" {
  description = "cAdvisor image, digest-pinned to match the Kamal accessory."
  type        = string
  default     = "gcr.io/cadvisor/cadvisor@sha256:3de2bd5203120b866d74a9b283b2ffb8ec382fbf9dc321814700c6ea6f44ec57"
}

variable "postgres_exporter_image" {
  description = "Prometheus postgres-exporter image, digest-pinned to match the Kamal accessory."
  type        = string
  default     = "quay.io/prometheuscommunity/postgres-exporter@sha256:38606faa38c54787525fb0ff2fd6b41b4cfb75d455c1df294927c5f611699b17"
}

variable "collector_service_name" {
  description = "Swarm service name for the collector; the app sends OTLP here and the collector's prometheus scrape targets resolve exporter services by their DNS names."
  type        = string
  default     = "observability-collector"
}

variable "node_exporter_service_name" {
  description = "Swarm service name for node-exporter; the collector scrapes it at <name>:9100."
  type        = string
  default     = "observability-node-exporter"
}

variable "cadvisor_service_name" {
  description = "Swarm service name for cAdvisor; the collector scrapes it at <name>:8080."
  type        = string
  default     = "observability-cadvisor"
}

variable "postgres_exporter_service_name" {
  description = "Swarm service name for postgres-exporter; the collector scrapes it at <name>:9187."
  type        = string
  default     = "observability-postgres-exporter"
}

variable "internal_network_id" {
  description = "ID of the internal overlay network the observability services share (and where postgres-exporter reaches platform-db). Referenced by ID to avoid the perpetual-diff forced replacement."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.internal_network_id != ""
    error_message = "internal_network_id must be set when enable = true."
  }
}

variable "traefik_network_id" {
  description = "ID of the Traefik overlay network the OpenObserve dashboard is routed on (by ID)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.traefik_network_id != ""
    error_message = "traefik_network_id must be set when enable = true."
  }
}

variable "traefik_network_name" {
  description = "Name of the Traefik overlay network (the Traefik swarm provider routes over it)."
  type        = string
  default     = "traefik"
}

variable "dashboard_host" {
  description = "Public host Traefik routes to the OpenObserve dashboard (OBSERVABILITY_HOST)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.dashboard_host != ""
    error_message = "dashboard_host must be set when enable = true."
  }
}

variable "data_path" {
  description = "Host bind-mount source for the OpenObserve data directory; the LUKS-encrypted volume reused from the Kamal deploy."
  type        = string
  default     = "/var/lib/crypt/observability/data"
}

variable "env_clear" {
  description = "Non-secret OpenObserve environment (retention, root email, R2 endpoint/bucket, SMTP). Merged over the module's static ZO_* defaults."
  type        = map(string)
  default     = {}
}

variable "env_secret" {
  description = "Secret OpenObserve environment (ZO_ROOT_USER_PASSWORD, ZO_S3_ACCESS_KEY, ZO_S3_SECRET_KEY, ZO_SMTP_PASSWORD), merged into the container env like the Kamal deploy does."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "http_port" {
  description = "Port OpenObserve listens on (ZO_HTTP_PORT); also the Traefik loadbalancer target port."
  type        = number
  default     = 5080
}

variable "otlp_org" {
  description = "OpenObserve organization the collector ingests into (OBSERVABILITY_OTLP_ORG)."
  type        = string
  default     = "default"
}

variable "otlp_auth" {
  description = "Basic auth header the collector uses to push to OpenObserve. Delivered as a swarm secret and read by the collector via the file provider, never inlined into the service env."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable || var.otlp_auth != ""
    error_message = "otlp_auth must be set when enable = true (an empty header makes the collector fail authentication silently and ingest nothing)."
  }
}

variable "postgres_exporter_uri" {
  description = "Non-secret Postgres URI the exporter connects to (host:port/dbname?sslmode=...), reaching platform-db over the internal network."
  type        = string
  default     = "platform-db:5432/postgres?sslmode=disable"
}

variable "postgres_exporter_user" {
  description = "Non-secret Postgres role the exporter authenticates as (matches the monitoring role provisioned by the observability support module)."
  type        = string
  default     = "monitoring"
}

variable "postgres_exporter_password" {
  description = "Password for the exporter's Postgres role, delivered as a swarm secret and read via DATA_SOURCE_PASS_FILE. Empty while dormant."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable || var.postgres_exporter_password != ""
    error_message = "postgres_exporter_password must be set when enable = true (an empty password leaves the exporter unable to connect)."
  }
}

variable "entrypoint" {
  description = "Traefik entrypoint the dashboard router binds to."
  type        = string
  default     = "websecure"
}

variable "healthcheck_path" {
  description = "HTTP path Traefik uses for its loadbalancer healthcheck against OpenObserve."
  type        = string
  default     = "/healthz"
}

variable "healthcheck_interval" {
  description = "Interval for the Traefik loadbalancer healthcheck."
  type        = string
  default     = "10s"
}

variable "placement_constraints" {
  description = "Swarm placement constraints; the stack is pinned to the node holding the LUKS observability volume and the docker socket exporters read."
  type        = list(string)
  default     = ["node.role==manager"]
}
