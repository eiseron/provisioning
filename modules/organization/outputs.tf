output "site_preview_trigger_token" {
  description = "Pipeline trigger token of the institutional-site preview deployer, if enabled"
  value       = local.site_preview_enabled ? module.site_preview[0].trigger_token : null
  sensitive   = true
}

output "group_id" {
  description = "Numeric ID of the organization's top-level GitLab group"
  value       = gitlab_group.this.id
}

output "group_full_path" {
  description = "Full path of the organization's top-level GitLab group"
  value       = gitlab_group.this.full_path
}
