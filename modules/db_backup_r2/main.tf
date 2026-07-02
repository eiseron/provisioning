data "cloudflare_api_token_permission_groups_list" "all" {}

locals {
  account_perm = {
    for group in data.cloudflare_api_token_permission_groups_list.all.result : group.name => group.id
    if contains(group.scopes, "com.cloudflare.api.account")
  }

  bucket_resource = "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.this.name}"

  lock_prefix = "${var.slug}/2"
}

resource "cloudflare_r2_bucket" "this" {
  account_id = var.cloudflare_account_id
  name       = "${var.slug}-backups"
  location   = var.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_r2_bucket_lock" "this" {
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.this.name

  rules = [
    {
      id      = "immutable-timestamped-backups-excludes-history"
      enabled = true
      prefix  = local.lock_prefix
      condition = {
        type            = "Age"
        max_age_seconds = var.backup_immutable_days * 24 * 60 * 60
      }
    }
  ]

  lifecycle {
    precondition {
      condition     = var.backup_immutable_days < var.gem_retention_days
      error_message = "backup_immutable_days (${var.backup_immutable_days}) must be below gem_retention_days (${var.gem_retention_days}); otherwise prune would try to delete a still-immutable object and R2 Object Lock would deny it, breaking rotation."
    }
  }
}

resource "cloudflare_account_token" "write" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - ${title(var.slug)} DB backup (R2 write)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = local.account_perm["Workers R2 Storage Write"] },
      ]
      resources = jsonencode({
        (local.bucket_resource) = "*"
      })
    }
  ]
}
