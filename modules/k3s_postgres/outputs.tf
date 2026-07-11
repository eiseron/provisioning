output "rw_host" {
  description = "In-cluster DNS name of the read-write (primary) Postgres service; use it as the DATABASE_URL host."
  value       = "${var.cluster_name}-rw.${var.namespace}"
}

output "cluster_name" {
  description = "Name of the CloudNativePG Cluster."
  value       = var.cluster_name
}
