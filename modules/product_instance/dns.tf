locals {
  app_dns_enabled = var.prod_host != null && var.zone_id != ""
}

resource "cloudflare_dns_record" "app" {
  count   = local.app_dns_enabled ? 1 : 0
  zone_id = var.zone_id
  name    = "app"
  type    = "A"
  content = var.prod_host.ip
  proxied = true
  ttl     = 1
}
