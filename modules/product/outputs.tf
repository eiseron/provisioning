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

output "ci_token" {
  description = "API token for the product CI service account (Developer in the product group). The product ops repo exposes it as a RELEASE_TOKEN group variable on the product group for release tagging and other product pipeline operations."
  value       = gitlab_group_service_account_access_token.ci.token
  sensitive   = true
}

output "ci_user_id" {
  description = "Numeric user ID of the CI service account. Useful for granting it explicit per-repo overrides (e.g. allowed_to_push on a protected branch) without escalating its group role."
  value       = gitlab_group_service_account.ci.service_account_id
}

output "robot_user_id" {
  description = "Numeric user ID of the ops/robot service account. Useful for the same scenario as ci_user_id but for the write-token robot."
  value       = gitlab_group_service_account.robot.service_account_id
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

output "preview_tenant" {
  description = "Everything the shared preview host needs to provision this product's tenant (name, PG password, authorized SSH key). Null when preview is disabled."
  sensitive   = true
  value = local.preview_enabled ? {
    name           = var.slug
    password       = random_password.tenant[0].result
    authorized_key = tls_private_key.preview[0].public_key_openssh
  } : null
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

output "admin_access_aud" {
  description = "Cloudflare Access AUD tag for the admin application, or null when the admin gate is disabled."
  value       = one(cloudflare_zero_trust_access_application.admin[*].aud)
}

output "media_r2_bucket" {
  description = "Name of the product's media R2 bucket, or null when media is disabled."
  value       = local.media_enabled ? local.media_bucket : null
}

output "media_r2_endpoint" {
  description = "S3-compatible endpoint for the product's media R2 bucket, or null when media is disabled."
  value       = local.media_enabled ? "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com" : null
}

output "media_r2_access_key_id" {
  description = "Access key id (R2 write token id) for the product's media bucket, or null when media is disabled."
  value       = local.media_enabled ? one(cloudflare_api_token.media_write[*].id) : null
  sensitive   = true
}

output "media_r2_secret_access_key" {
  description = "Secret access key (sha256 of the R2 write token) for the product's media bucket, or null when media is disabled."
  value       = local.media_enabled ? sha256(one(cloudflare_api_token.media_write[*].value)) : null
  sensitive   = true
}

output "media_public_base_url" {
  description = "Public base URL the product serves media from (the R2 custom domain), or null when media is disabled."
  value       = local.media_enabled ? "https://${local.media_host}" : null
}
