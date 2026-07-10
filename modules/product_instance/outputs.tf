output "app_project_id" {
  description = "Numeric ID of the app project (internal when app_repo is set, else from app_project_id input)."
  value       = local._app_project_id
}

output "app_project_path" {
  description = "Full path of the app project."
  value       = local._app_project_path
}

output "site_project_id" {
  description = "Numeric ID of the site project (internal when site_repo is set, else from site_preview.site_project_id)."
  value       = local._site_project_id
}

output "site_project_path" {
  description = "Full path of the site project."
  value       = local._site_project_path
}
