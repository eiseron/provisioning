variable "enable" {
  description = "Create the shared platform Postgres via CloudNativePG. Keep false so the module lands dormant until the cluster exists."
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Namespace the Postgres Cluster runs in."
  type        = string
  default     = "platform"
}

variable "cluster_name" {
  description = "Name of the CloudNativePG Cluster; also the read-write service prefix (<name>-rw), kept as platform-db so the app DATABASE_URL host is stable."
  type        = string
  default     = "platform-db"
}

variable "instances" {
  description = "Number of Postgres instances (1 primary + N-1 replicas). 2 gives failover across the two nodes."
  type        = number
  default     = 2
}

variable "postgres_image" {
  description = "CloudNativePG Postgres image, digest-pinnable in prod."
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:18"
}

variable "storage_size" {
  description = "PVC size per instance."
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "StorageClass for the instance PVCs (local-path, on the encrypted volume)."
  type        = string
  default     = "local-path"
}

variable "operator_namespace" {
  description = "Namespace the CloudNativePG operator is installed in."
  type        = string
  default     = "cnpg-system"
}

variable "operator_chart_version" {
  description = "Pinned CloudNativePG Helm chart version."
  type        = string
  default     = "0.22.1"
}

variable "superuser_password" {
  description = "Postgres superuser password, delivered as a secret CloudNativePG binds as the cluster superuser. Empty while dormant."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable || var.superuser_password != ""
    error_message = "superuser_password must be set when enable = true."
  }
}

variable "superuser_username" {
  description = "Postgres superuser role name. Generic default so the module is reusable; the consumer sets it to match its deployment."
  type        = string
  default     = "postgres"
}

variable "backup" {
  description = "Continuous backup + PITR to an S3-compatible store (R2) via CloudNativePG barmanObjectStore. When enabled, WAL and base backups stream to destination_path. Fields: endpoint_url (R2 S3 endpoint), destination_path (s3://bucket/path), access_key_id and secret_access_key (R2 credentials)."
  type = object({
    enabled           = optional(bool, false)
    endpoint_url      = optional(string, "")
    destination_path  = optional(string, "")
    access_key_id     = optional(string, "")
    secret_access_key = optional(string, "")
  })
  default   = {}
  sensitive = true

  validation {
    condition = !var.backup.enabled || (
      var.backup.endpoint_url != "" &&
      var.backup.destination_path != "" &&
      var.backup.access_key_id != "" &&
      var.backup.secret_access_key != ""
    )
    error_message = "backup.endpoint_url, destination_path, access_key_id and secret_access_key must all be set when backup.enabled = true."
  }
}
