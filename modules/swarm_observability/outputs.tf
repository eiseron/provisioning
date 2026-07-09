output "service_name" {
  description = "Swarm service name of OpenObserve; the stable DNS the collector pushes to."
  value       = var.service_name
}

output "collector_otlp_endpoint" {
  description = "OTLP/HTTP endpoint the app should send telemetry to (the collector's receiver on the internal network). Wire it into the app's OBSERVABILITY_OTLP_ENDPOINT, replacing the Kamal observability-web-<sha> host."
  value       = var.enable ? "http://${var.collector_service_name}:4318" : null
}

output "dashboard_host" {
  description = "Public host Traefik routes to the OpenObserve dashboard."
  value       = var.dashboard_host
}
