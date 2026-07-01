output "domain" {
  description = "Public host of the GlitchTip dashboard."
  value       = local.domain
}

output "database" {
  description = "Postgres role/database slug used by GlitchTip on the shared platform Postgres."
  value       = local.slug
}
