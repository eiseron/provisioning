output "site_preview_trigger_token" {
  description = "Pipeline trigger token of the institutional-site preview deployer, if enabled"
  value       = local.site_preview_enabled ? module.site_preview[0].trigger_token : null
  sensitive   = true
}

output "repo_ids" {
  description = "Map of repo slug to numeric GitLab project ID."
  value       = { for k, v in module.repo : k => v.id }
}

output "repo_paths" {
  description = "Map of repo slug to path_with_namespace."
  value       = { for k, v in module.repo : k => v.path_with_namespace }
}

output "service_account_id" {
  description = "Numeric service account user ID of the org-level CI robot. Null if service_account was not configured."
  value       = length(gitlab_group_service_account.robot) > 0 ? gitlab_group_service_account.robot[0].service_account_id : null
}

output "service_account_username" {
  description = "Username of the org-level CI robot service account. Null if service_account was not configured."
  value       = length(gitlab_group_service_account.robot) > 0 ? gitlab_group_service_account.robot[0].username : null
}

output "site_pages_project_name" {
  description = "Name of the institutional site Cloudflare Pages project. Null if cloudflare_account_id is not set."
  value       = local.site_pages_enabled ? cloudflare_pages_project.site[0].name : null
}

output "group_id" {
  description = "Numeric ID of the organization's top-level GitLab group"
  value       = gitlab_group.this.id
}

output "group_full_path" {
  description = "Full path of the organization's top-level GitLab group"
  value       = gitlab_group.this.full_path
}

output "avatar_path" {
  description = "Echoes var.avatar_path back, so callers that need the same image for sibling resources (a subgroup, per-product repos) can reference this output instead of repeating their own literal path."
  value       = var.avatar_path
}
