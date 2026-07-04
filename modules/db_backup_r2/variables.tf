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

variable "backup_immutable_days" {
  description = "Days each backup object stays immutable via R2 Object Lock (Age condition). Defends against clobber by the write-capable backup token. Must stay below gem_retention_days so the immutability window expires before pruning deletes expired backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_immutable_days >= 1
    error_message = "backup_immutable_days must be at least 1."
  }
}

variable "gem_retention_days" {
  description = "Mirror of the gem's PROD_BACKUP_RETENTION_DAYS (days after which db backup prunes an object). Keep in sync with the deployed gem/accessory config: the module cross-checks that backup_immutable_days stays below it, so the prune never tries to delete a still-immutable object (which R2 Object Lock would deny, silently breaking rotation)."
  type        = number
  default     = 15
}

variable "ops_project_id" {
  description = "GitLab numeric project ID of the product ops repo. When set, the module creates PROD_BACKUP_*, PROD_DRILL_*, and PROD_BACKUP_LOCK_PREFIX CI variables in that project (environment=production, protected=true)."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.ops_project_id == null || can(tonumber(var.ops_project_id))
    error_message = "ops_project_id must be a numeric GitLab project ID or null."
  }
}
