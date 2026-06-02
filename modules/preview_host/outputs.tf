output "vps_ipv4" {
  description = "Public IPv4 address of the preview host; consumed by the consumer's Ansible inventory for direct SSH"
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 address of the preview host"
  value       = hcloud_server.this.ipv6_address
}

output "tunnel_id" {
  description = "Cloudflare tunnel UUID; consumed by the consumer's ops repo to point the wildcard CNAME at <id>.cfargotunnel.com"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_token" {
  description = "Cloudflared registration token; consumed by Ansible on the host"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
  sensitive   = true
}

output "ssh_hostname" {
  description = "Hostname that cloudflared brokers for SSH; consumed by the deployer scripts"
  value       = var.ssh_hostname
}

output "service_token_client_id" {
  description = "Cloudflare Access service token client_id; consumed by an Access policy in the consumer's ops repo"
  value       = cloudflare_zero_trust_access_service_token.ci_runner.client_id
}

output "service_token_client_secret" {
  description = "Cloudflare Access service token client_secret; injected as a CI variable in the consumer's ops repo"
  value       = cloudflare_zero_trust_access_service_token.ci_runner.client_secret
  sensitive   = true
}
