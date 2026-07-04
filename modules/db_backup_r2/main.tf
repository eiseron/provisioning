data "cloudflare_api_token_permission_groups_list" "all" {}

locals {
  account_perm = {
    for group in data.cloudflare_api_token_permission_groups_list.all.result : group.name => group.id
    if contains(group.scopes, "com.cloudflare.api.account")
  }

  bucket_perm = {
    for group in data.cloudflare_api_token_permission_groups_list.all.result : group.name => group.id
    if anytrue([for scope in group.scopes : strcontains(scope, "edge.r2.bucket")])
  }

  bucket_resource = "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.this.name}"

  lock_prefix = "${var.slug}/2"

  ci_vars = var.ops_project_id != null ? {
    PROD_BACKUP_AWS_ACCESS_KEY_ID     = { value = cloudflare_account_token.write.id, masked = true }
    PROD_BACKUP_AWS_SECRET_ACCESS_KEY = { value = sha256(cloudflare_account_token.write.value), masked = true }
    PROD_DRILL_AWS_ACCESS_KEY_ID      = { value = cloudflare_account_token.write.id, masked = true }
    PROD_DRILL_AWS_SECRET_ACCESS_KEY  = { value = sha256(cloudflare_account_token.write.value), masked = true }
  } : {}
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

resource "cloudflare_account_token" "read" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - ${title(var.slug)} DB backup (R2 read)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = local.bucket_perm["Workers R2 Storage Bucket Item Read"] },
      ]
      resources = jsonencode({
        (local.bucket_resource) = "*"
      })
    }
  ]
}

resource "gitlab_project_variable" "ci_vars" {
  for_each          = local.ci_vars
  project           = var.ops_project_id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = true
  environment_scope = "production"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_project_variable" "lock_prefix" {
  count             = var.ops_project_id != null ? 1 : 0
  project           = var.ops_project_id
  key               = "PROD_BACKUP_LOCK_PREFIX"
  value             = local.lock_prefix
  masked            = false
  protected         = true
  environment_scope = "production"

  lifecycle {
    prevent_destroy = true
  }
}
