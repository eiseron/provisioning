output "bucket" {
  description = "R2 bucket name holding the product's database backups."
  value       = cloudflare_r2_bucket.this.name
}

output "write_access_key_id" {
  description = "R2 S3 access key id for the backup accessory (write scope)."
  value       = cloudflare_api_token.write.id
  sensitive   = true
}

output "write_secret_access_key" {
  description = "R2 S3 secret access key (sha256 of the token value) for the backup accessory (write scope)."
  value       = sha256(cloudflare_api_token.write.value)
  sensitive   = true
}

output "read_access_key_id" {
  description = "R2 S3 access key id for the restore drill (read scope)."
  value       = cloudflare_api_token.read.id
  sensitive   = true
}

output "read_secret_access_key" {
  description = "R2 S3 secret access key (sha256 of the token value) for the restore drill (read scope)."
  value       = sha256(cloudflare_api_token.read.value)
  sensitive   = true
}
