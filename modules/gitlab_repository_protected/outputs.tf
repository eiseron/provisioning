output "id" {
  description = "Numeric ID of the created GitLab project."
  value       = gitlab_project.this.id
}

output "path_with_namespace" {
  description = "Full path of the project including group namespace."
  value       = gitlab_project.this.path_with_namespace
}
