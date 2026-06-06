resource "cloudflare_zero_trust_access_policy" "preview" {
  count = local.preview_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = "${var.slug} preview access"
  decision   = "allow"
  include    = [for domain in var.preview_access_email_domains : { email_domain = { domain = domain } }]

  lifecycle {
    precondition {
      condition     = length(var.preview_access_email_domains) > 0
      error_message = "preview_access_email_domains must list at least one allowed email domain when preview is enabled."
    }
  }
}

resource "cloudflare_zero_trust_access_application" "preview" {
  count = local.preview_enabled ? 1 : 0

  account_id           = var.cloudflare_account_id
  name                 = "${var.slug} previews"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = false
  destinations = [
    { type = "public", uri = "*-preview.${var.domain}" },
  ]
  policies = [
    { id = cloudflare_zero_trust_access_policy.preview[0].id },
  ]
}
