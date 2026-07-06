locals {
  assets_enabled     = var.r2_buckets.cdn_domain != "" && var.cloudflare_account_id != ""
  sourcemaps_enabled = local.assets_enabled && var.r2_buckets.sourcemaps_enabled
  cdn_enabled        = local.assets_enabled && var.r2_buckets.zone_id != ""

  assets_bucket_name     = "${var.slug}-assets"
  sourcemaps_bucket_name = "${var.slug}-sourcemaps"

  assets_token_resources = merge(
    { "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${local.assets_bucket_name}" = "*" },
    local.sourcemaps_enabled ? {
      "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${local.sourcemaps_bucket_name}" = "*"
    } : {}
  )

  assets_ops_vars = local.assets_enabled ? {
    ASSETS_R2_BUCKET            = cloudflare_r2_bucket.assets[0].name
    ASSETS_R2_ENDPOINT          = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
    ASSETS_R2_ACCESS_KEY_ID     = cloudflare_api_token.assets_write[0].id
    ASSETS_R2_SECRET_ACCESS_KEY = sha256(cloudflare_api_token.assets_write[0].value)
    ASSETS_CDN_URL              = "https://${var.r2_buckets.cdn_domain}"
  } : {}
}

resource "cloudflare_r2_bucket" "assets" {
  count      = local.assets_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = local.assets_bucket_name
  location   = var.r2_buckets.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_r2_bucket" "sourcemaps" {
  count      = local.sourcemaps_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = local.sourcemaps_bucket_name
  location   = var.r2_buckets.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_r2_custom_domain" "cdn" {
  count       = local.cdn_enabled ? 1 : 0
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.assets[0].name
  domain      = var.r2_buckets.cdn_domain
  zone_id     = var.r2_buckets.zone_id
  enabled     = true
  min_tls     = "1.2"
}

resource "cloudflare_api_token" "assets_write" {
  count = local.assets_enabled ? 1 : 0
  name  = "Service Token - ${title(var.slug)} assets (R2 write)"

  policies = [
    {
      effect            = "allow"
      permission_groups = [{ id = var.r2_buckets.assets_write_permission }]
      resources         = jsonencode(local.assets_token_resources)
    }
  ]
}

resource "gitlab_project_variable" "assets_ops" {
  for_each          = local.assets_ops_vars
  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = contains(["ASSETS_R2_ACCESS_KEY_ID", "ASSETS_R2_SECRET_ACCESS_KEY"], each.key)
  protected         = true
  environment_scope = "production"
}
