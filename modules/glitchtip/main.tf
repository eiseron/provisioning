locals {
  slug     = "glitchtip"
  database = "glitchtip_prod"
  domain   = "${var.subdomain}.${var.zone_domain}"

  # GlitchTip uses the shared platform Postgres (role/db provisioned via the
  # existing tenant flow: `eiseron prod tenant` with PROD_TENANT_SLUG=glitchtip)
  # and a co-located redis accessory reachable as glitchtip-redis on the kamal net.
  # Only maskable secrets ship as variables; DATABASE_URL is assembled from the
  # masked password in .kamal/secrets at deploy time (a URL can't be masked).
  deploy_vars = var.enable ? {
    PROD_TENANT_SLUG     = { value = local.slug, masked = false }
    PROD_TENANT_PASSWORD = { value = random_password.db.result, masked = true }
    GLITCHTIP_SECRET_KEY = { value = random_password.secret_key.result, masked = true }
    GLITCHTIP_DB_NAME    = { value = local.database, masked = false }
    GLITCHTIP_HOST       = { value = local.domain, masked = false }
    GLITCHTIP_IMAGE      = { value = var.image, masked = false }
  } : {}
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
