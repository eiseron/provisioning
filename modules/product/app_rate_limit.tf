resource "cloudflare_ruleset" "app_rate_limit" {
  count = var.app_subdomain == "" ? 0 : 1

  zone_id     = cloudflare_zone.this.id
  name        = "${var.slug} app rate limit"
  description = "Per-IP request rate limit on the VPS-served app host"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [{
    action      = "block"
    description = "Block an IP exceeding the per-minute request budget on the app host"
    enabled     = true
    expression  = "(http.host eq \"${var.app_subdomain}.${var.domain}\")"
    ratelimit = {
      characteristics     = ["ip.src", "cf.colo.id"]
      period              = 60
      requests_per_period = var.app_rate_limit_requests_per_minute
      mitigation_timeout  = 60
    }
  }]
}
