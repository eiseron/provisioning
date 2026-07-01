output "domain" {
  description = "Public host of the error monitoring dashboard."
  value       = local.domain
}

output "database" {
  description = "Postgres role/database slug used by error monitoring on the shared platform Postgres."
  value       = local.slug
}
