output "group_id" {
  description = "ID of the product subgroup."
  value       = gitlab_group.this.id
}

output "repository_ids" {
  description = "Map of repo name to GitLab project ID."
  value       = { for key, repo in module.repository : key => repo.id }
}

output "robot_write_token" {
  description = "Write API token for the product ops service account."
  value       = gitlab_group_service_account_access_token.robot_write.token
  sensitive   = true
}

output "robot_readonly_token" {
  description = "Read-only API token for the product ops service account."
  value       = gitlab_group_service_account_access_token.robot_readonly.token
  sensitive   = true
}

output "zone_id" {
  description = "Cloudflare zone ID."
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Cloudflare nameservers to set at the domain registrar."
  value       = cloudflare_zone.this.name_servers
}

output "state_bucket" {
  description = "R2 bucket name for the product ops Terraform state."
  value       = cloudflare_r2_bucket.state.name
}

output "preview_authorized_key" {
  description = "Public SSH key to authorize on the shared preview host for this product (null when preview is disabled)."
  value       = local.preview_enabled ? tls_private_key.preview[0].public_key_openssh : null
}

output "setup_package" {
  description = "Everything the product ops repo needs to bootstrap its own Terraform."
  sensitive   = true
  value = {
    state_bucket   = cloudflare_r2_bucket.state.name
    zone_id        = cloudflare_zone.this.id
    nameservers    = cloudflare_zone.this.name_servers
    ops_cf_token   = cloudflare_account_token.ops_write.value
    state_r2_write = cloudflare_api_token.state_write.value
  }
}

output "ops_credentials" {
  description = "Credentials the product ops repo's CI needs to run its own Terraform (write = apply, readonly = plan)."
  sensitive   = true
  value = {
    ops_project_id            = module.repository["${var.slug}-ops"].id
    cloudflare_token          = cloudflare_account_token.ops_write.value
    cloudflare_token_readonly = cloudflare_account_token.ops_readonly.value
    gitlab_token              = gitlab_group_service_account_access_token.robot_write.token
    gitlab_token_readonly     = gitlab_group_service_account_access_token.robot_readonly.token
    r2_access_key             = cloudflare_api_token.state_write.id
    r2_secret_key             = cloudflare_api_token.state_write.value
    r2_access_key_readonly    = cloudflare_api_token.state_readonly.id
    r2_secret_key_readonly    = cloudflare_api_token.state_readonly.value
  }
}
