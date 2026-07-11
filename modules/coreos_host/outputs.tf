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
