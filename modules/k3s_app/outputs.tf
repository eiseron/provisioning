output "service_name" {
  description = "In-cluster name of the app Service."
  value       = var.name
}

output "manages_namespace" {
  description = "Whether this module owns (creates) the app namespace. False when the platform already owns it."
  value       = var.enable && var.manage_namespace
}
