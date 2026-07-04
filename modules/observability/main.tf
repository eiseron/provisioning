data "cloudflare_api_token_permission_groups_list" "all" {}

locals {
  slug   = "observability"
  bucket = "observability"
  domain = "${var.subdomain}.${var.zone_domain}"

  account_perm = {
    for group in data.cloudflare_api_token_permission_groups_list.all.result : group.name => group.id
    if contains(group.scopes, "com.cloudflare.api.account")
  }

  bucket_resource = "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.data.name}"

  r2_endpoint = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"

  root_pw = nonsensitive(var.root_password != "") ? var.root_password : random_password.root.result

  pg_monitor_pw = random_password.pg_monitor.result

  deploy_vars = merge(
    var.enable ? {
      OBSERVABILITY_HOST                 = { value = local.domain, masked = false }
      OBSERVABILITY_ROOT_EMAIL           = { value = var.root_email, masked = false }
      OBSERVABILITY_ROOT_PASSWORD        = { value = local.root_pw, masked = true }
      OBSERVABILITY_R2_BUCKET            = { value = cloudflare_r2_bucket.data.name, masked = false }
      OBSERVABILITY_R2_ENDPOINT          = { value = local.r2_endpoint, masked = false }
      OBSERVABILITY_R2_ACCESS_KEY_ID     = { value = cloudflare_account_token.rw.id, masked = true }
      OBSERVABILITY_R2_SECRET_ACCESS_KEY = { value = sha256(cloudflare_account_token.rw.value), masked = true }
      OBSERVABILITY_OTLP_BASIC           = { value = base64encode("${var.root_email}:${local.root_pw}"), masked = true }
      OBSERVABILITY_PG_MONITOR_USER      = { value = var.pg_monitor_user, masked = false }
      OBSERVABILITY_PG_MONITOR_PASSWORD  = { value = local.pg_monitor_pw, masked = true }
    } : {},
    var.enable && nonsensitive(var.smtp_password) != "" ? {
      OBSERVABILITY_SMTP_PASSWORD = { value = var.smtp_password, masked = true }
      OBSERVABILITY_SMTP_USER     = { value = var.smtp.user, masked = false }
      OBSERVABILITY_SMTP_HOST     = { value = var.smtp.host, masked = false }
      OBSERVABILITY_SMTP_PORT     = { value = var.smtp.port, masked = false }
      OBSERVABILITY_SMTP_FROM     = { value = var.smtp.from, masked = false }
    } : {}
  )
}

resource "random_password" "pg_monitor" {
  length  = 32
  special = false
  keepers = { epoch = var.pg_monitor_password_epoch }
}

resource "random_password" "root" {
  length           = 32
  special          = true
  override_special = "@"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  keepers          = { epoch = var.root_password_epoch }
}

resource "cloudflare_r2_bucket" "data" {
  account_id = var.cloudflare_account_id
  name       = local.bucket
  location   = var.r2_location != "" ? var.r2_location : null

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_account_token" "rw" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - Observability (R2 read/write)"

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

resource "cloudflare_dns_record" "dashboard" {
  count   = var.enable ? 1 : 0
  zone_id = var.zone_id
  name    = var.subdomain
  type    = "A"
  content = var.prod_host_ip
  proxied = true
  ttl     = 1

  lifecycle {
    precondition {
      condition     = var.root_email != ""
      error_message = "observability requires root_email to bootstrap the OpenObserve root user."
    }
  }
}

resource "gitlab_project_variable" "deploy" {
  for_each = local.deploy_vars

  project   = var.ops_project_id
  key       = each.key
  value     = each.value.value
  masked    = each.value.masked
  protected = true
}
