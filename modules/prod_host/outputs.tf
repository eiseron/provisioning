output "vps_ipv4" {
  description = "Public IPv4 address of the production host; consumed by the Ansible inventory for SSH and by the DNS record"
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 address of the production host"
  value       = hcloud_server.this.ipv6_address
}
