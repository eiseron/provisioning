output "vps_ipv4" {
  description = "Public IPv4 address of the preview host; consumed by the consumer's Ansible inventory for direct SSH and by the wildcard DNS record"
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 address of the preview host"
  value       = hcloud_server.this.ipv6_address
}
