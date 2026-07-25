output "group_id" {
  description = "Numeric ID of the subgroup"
  value       = gitlab_group.this.id
}

output "group_full_path" {
  description = "Full path of the subgroup"
  value       = gitlab_group.this.full_path
}

output "repo_ids" {
  description = "Map of repo slug to numeric GitLab project ID."
  value       = { for k, v in module.repo : k => v.id }
}

output "repo_paths" {
  description = "Map of repo slug to path_with_namespace."
  value       = { for k, v in module.repo : k => v.path_with_namespace }
}
