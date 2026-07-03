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

output "group_id" {
  description = "Numeric ID of the organization's top-level GitLab group"
  value       = gitlab_group.this.id
}

output "group_full_path" {
  description = "Full path of the organization's top-level GitLab group"
  value       = gitlab_group.this.full_path
}
