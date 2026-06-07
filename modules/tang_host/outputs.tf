output "vps_ipv4" {
  description = "Public IPv4 of the Tang host; consumed by the Tang provision inventory and the prod host's Clevis binding URL"
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 of the Tang host"
  value       = hcloud_server.this.ipv6_address
}
