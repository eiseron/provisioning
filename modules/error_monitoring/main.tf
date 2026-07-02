locals {
  slug     = "error_monitoring"
  database = "error_monitoring_prod"
  domain   = "${var.subdomain}.${var.zone_domain}"

  deploy_vars = merge(
    var.enable ? {
      PROD_TENANT_SLUG            = { value = local.slug, masked = false }
      PROD_TENANT_PASSWORD        = { value = random_password.db.result, masked = true }
      ERROR_MONITORING_SECRET_KEY = { value = random_password.secret_key.result, masked = true }
      ERROR_MONITORING_DB_NAME    = { value = local.database, masked = false }
      ERROR_MONITORING_HOST       = { value = local.domain, masked = false }
    } : {},
    var.enable && var.smtp_password != "" ? {
      ERROR_MONITORING_SMTP_PASSWORD = { value = var.smtp_password, masked = true }
      ERROR_MONITORING_SMTP_USER     = { value = urlencode(var.smtp.user), masked = false }
      ERROR_MONITORING_SMTP_HOST     = { value = var.smtp.host, masked = false }
      ERROR_MONITORING_SMTP_PORT     = { value = var.smtp.port, masked = false }
      ERROR_MONITORING_FROM_EMAIL    = { value = var.smtp.from, masked = false }
    } : {}
  )
}

resource "random_password" "secret_key" {
  length  = 50
  special = false
  keepers = { epoch = var.secret_key_epoch }
}

resource "random_password" "db" {
  length  = 32
  special = false
  keepers = { epoch = var.db_password_epoch }
}

resource "cloudflare_dns_record" "dashboard" {
  count   = var.enable ? 1 : 0
  zone_id = var.zone_id
  name    = var.subdomain
  type    = "A"
  content = var.prod_host_ip
  proxied = true
  ttl     = 1
}

resource "gitlab_project_variable" "deploy" {
  for_each = local.deploy_vars

  project   = var.ops_project_id
  key       = each.key
  value     = each.value.value
  masked    = each.value.masked
  protected = true
}
