output "service_name" {
  description = "In-cluster name of the app Service."
  value       = var.name
}

output "manages_namespace" {
  description = "Whether this module owns (creates) the app namespace. False when the platform already owns it."
  value       = var.enable && var.manage_namespace
}

output "router_hosts" {
  description = "Every host the IngressRoute matches (app_host plus extra_hosts)."
  value       = local.router_hosts
}

output "migrate_container_present" {
  description = "Whether the deployment runs a migrate init container before the app (true when migrate_command is set)."
  value       = length(var.migrate_command) > 0
}

output "env_clear" {
  description = "The non-secret environment the app container receives, after the caller's extra variables are merged in."
  value       = var.env_clear
}

output "env_secret_keys" {
  description = "The names (not values) of the secret environment variables delivered to the app via its Secret, so callers can assert coverage without exposing the values."
  value       = nonsensitive(keys(var.env_secret))
}
