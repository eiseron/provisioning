locals {
  media_enabled = var.media_subdomain != null
  media_bucket  = "${var.slug}-media"
  media_host    = "${var.media_subdomain}.${var.domain}"

  media_ops_vars = local.media_enabled ? {
    MEDIA_R2_BUCKET = {
      value  = local.media_bucket
      masked = false
      scope  = "production"
    }
    MEDIA_R2_ENDPOINT = {
      value  = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
      masked = false
      scope  = "production"
    }
    MEDIA_R2_ACCESS_KEY_ID = {
      value  = one(cloudflare_api_token.media_write[*].id)
      masked = true
      scope  = "production"
    }
    MEDIA_R2_SECRET_ACCESS_KEY = {
      value  = sha256(one(cloudflare_api_token.media_write[*].value))
      masked = true
      scope  = "production"
    }
    MEDIA_PUBLIC_BASE_URL = {
      value  = "https://${local.media_host}"
      masked = false
      scope  = "production"
    }
  } : {}
}

resource "cloudflare_r2_bucket" "media" {
  count = local.media_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = local.media_bucket
  location   = var.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_r2_custom_domain" "media" {
  count = local.media_enabled ? 1 : 0

  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.media[0].name
  domain      = local.media_host
  zone_id     = cloudflare_zone.this.id
  enabled     = true
  min_tls     = "1.2"
}

resource "cloudflare_api_token" "media_write" {
  count = local.media_enabled ? 1 : 0

  name = "Service Token - ${title(var.slug)} Media (R2 write)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = local.cfl_account_perm["Workers R2 Storage Write"] },
      ]
      resources = jsonencode({
        "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.media[0].name}" = "*"
      })
    }
  ]
}

resource "gitlab_project_variable" "media_ops" {
  for_each = local.media_ops_vars

  project           = module.repository[local.ops_repo_key].id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = true
  environment_scope = each.value.scope

  lifecycle {
    prevent_destroy = true
  }
}
