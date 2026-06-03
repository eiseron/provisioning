output "tunnel_id" {
  description = "Cloudflare tunnel UUID; point a wildcard CNAME at <id>.cfargotunnel.com to route through the tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_token" {
  description = "Cloudflared registration token; consumed by cloudflared on the host"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
  sensitive   = true
}

output "service_token_client_id" {
  description = "Cloudflare Access service token client_id; consumed by an Access policy gating the preview domain"
  value       = cloudflare_zero_trust_access_service_token.ci_runner.client_id
}

output "service_token_client_secret" {
  description = "Cloudflare Access service token client_secret; injected as a CI variable for the deploy healthcheck"
  value       = cloudflare_zero_trust_access_service_token.ci_runner.client_secret
  sensitive   = true
}
