output "traefik_network_id" {
  description = "ID of the Traefik overlay network; app services attach to it by ID to avoid the perpetual-diff forced replacement."
  value       = var.enable ? docker_network.traefik[0].id : null
}

output "traefik_network_name" {
  description = "Name of the Traefik overlay network."
  value       = var.traefik_network_name
}

output "internal_network_id" {
  description = "ID of the internal overlay network for east-west service traffic."
  value       = var.enable ? docker_network.internal[0].id : null
}

output "internal_network_name" {
  description = "Name of the internal overlay network."
  value       = var.internal_network_name
}
