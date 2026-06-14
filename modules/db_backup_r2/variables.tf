variable "slug" {
  description = "Product slug; the backup bucket is named <slug>-backups."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the backup bucket and tokens."
  type        = string
}

variable "r2_location" {
  description = "Cloudflare R2 location hint for the backup bucket."
  type        = string
  default     = "ENAM"
}
