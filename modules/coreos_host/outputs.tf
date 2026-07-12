output "vps_ipv4" {
  description = "Public IPv4 address of the host."
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 address of the host."
  value       = hcloud_server.this.ipv6_address
}

output "firewall_id" {
  description = "ID of the Hetzner Cloud Firewall attached to the host."
  value       = hcloud_firewall.this.id
}

output "data_volume_id" {
  description = "ID of the persistent Hetzner Cloud data volume, or null when data_volume is disabled. Used by the rollback runbook to reattach the same encrypted volume to a replacement host."
  value       = var.data_volume.enable ? hcloud_volume.data[0].id : null
}
