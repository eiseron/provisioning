output "full_name" {
  description = "Full name of the repository (owner/name)."
  value       = github_repository.this.full_name
}

output "html_url" {
  description = "URL of the repository on GitHub."
  value       = github_repository.this.html_url
}
