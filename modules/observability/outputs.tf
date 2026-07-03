output "domain" {
  description = "Public host of the observability dashboard."
  value       = local.domain
}

output "bucket" {
  description = "R2 bucket name backing OpenObserve storage."
  value       = cloudflare_r2_bucket.data.name
}
