output "vps_ipv4" {
  description = "Public IPv4 of the production host (null while disabled)"
  value       = var.enable ? module.host[0].vps_ipv4 : null
}

output "vps_ipv6" {
  description = "Public IPv6 of the production host (null while disabled)"
  value       = var.enable ? module.host[0].vps_ipv6 : null
}

output "tang_host_ipv4" {
  description = "Public IPv4 of the key server (Tang) host (null unless enable && encrypt_db)"
  value       = var.enable && var.encrypt_db ? module.tang[0].vps_ipv4 : null
}

output "deploy_public_key" {
  description = "Public key of the deploy user (authorized on the host; Kamal authenticates with the matching private key)"
  value       = tls_private_key.deploy.public_key_openssh
}

output "deploy_private_key" {
  description = "Private key for the deploy user; distribute to each product-ops as PROD_SSH_PRIVATE_KEY for Kamal"
  value       = tls_private_key.deploy.private_key_openssh
  sensitive   = true
}
