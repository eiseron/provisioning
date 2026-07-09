variable "enable" {
  description = "Create the shared platform Postgres service. Keep false so the module lands dormant until the cutover."
  type        = bool
  default     = false
}

variable "internal_network_id" {
  description = "ID of the overlay network app services reach Postgres on (referenced by ID to avoid the perpetual-diff forced replacement)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable || var.internal_network_id != ""
    error_message = "internal_network_id must be set when enable = true."
  }
}

variable "service_name" {
  description = "Swarm service name; kept as platform-db so the assembled DATABASE_URL host is unchanged from the Kamal accessory."
  type        = string
  default     = "platform-db"
}

variable "postgres_image" {
  description = "Postgres image, digest-pinned (matches the postgres:18 the Kamal platform accessory runs). A bare tag causes a perpetual diff."
  type        = string
  default     = "postgres:18@sha256:22c89fe0d0f507606260237fd55e51f6137f58b2d5bcf6152242b96d9fe8f9a4"
}

variable "pg_admin_user" {
  description = "Postgres superuser role (only applied on a fresh data dir; the existing prod volume already has it)."
  type        = string
  default     = "eiseron"
}

variable "postgres_password" {
  description = "Superuser password, delivered as a swarm secret and read via POSTGRES_PASSWORD_FILE. Empty while dormant."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable || var.postgres_password != ""
    error_message = "postgres_password must be set when enable = true."
  }
}

variable "data_path" {
  description = "Host bind-mount source for the Postgres data directory; the LUKS-encrypted volume reused from the Kamal deploy."
  type        = string
  default     = "/var/lib/crypt/postgres"
}

variable "placement_constraints" {
  description = "Swarm placement constraints; Postgres is pinned to the node holding the LUKS data volume."
  type        = list(string)
  default     = ["node.role==manager"]
}
