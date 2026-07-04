locals {
  admin_gate_enabled = var.admin_gate_origin_ip != null
  admin_gate_host    = "${var.admin_gate_subdomain}.${var.domain}"

  admin_gate_ops_vars = local.admin_gate_enabled ? {
    ADMIN_ACCESS_AUDIENCES = {
      value  = one(cloudflare_zero_trust_access_application.admin[*].aud)
      masked = true
      scope  = "production"
    }
    ADMIN_ACCESS_ISSUER = {
      value  = "https://${var.admin_gate_auth_domain}"
      masked = false
      scope  = "*"
    }
    ADMIN_ACCESS_CERTS_URL = {
      value  = "https://${var.admin_gate_auth_domain}/cdn-cgi/access/certs"
      masked = false
      scope  = "*"
    }
    ADMIN_ACCESS_HOST = {
      value  = local.admin_gate_host
      masked = false
      scope  = "production"
    }
  } : {}
}

resource "cloudflare_zero_trust_access_policy" "admin" {
  count = local.admin_gate_enabled ? 1 : 0

  account_id                     = var.cloudflare_account_id
  name                           = "${var.slug} admin (owner only)"
  decision                       = "allow"
  purpose_justification_required = true
  purpose_justification_prompt   = "Reason for accessing the ${var.slug} admin"

  include = [for email in var.admin_gate_emails : { email = { email = email } }]

  require = [
    { auth_method = { auth_method = "mfa" } },
  ]

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = length(var.admin_gate_emails) > 0
      error_message = "admin_gate_emails must list at least one allowed email when the admin gate is enabled."
    }

    precondition {
      condition     = var.admin_gate_auth_domain != null
      error_message = "admin_gate_auth_domain is required when the admin gate is enabled."
    }
  }
}

resource "cloudflare_zero_trust_access_application" "admin" {
  count = local.admin_gate_enabled ? 1 : 0

  account_id                = var.cloudflare_account_id
  name                      = "${var.slug} admin"
  type                      = "self_hosted"
  session_duration          = "30m"
  app_launcher_visible      = false
  auto_redirect_to_identity = false

  destinations = [
    { type = "public", uri = local.admin_gate_host },
  ]

  policies = [
    { id = cloudflare_zero_trust_access_policy.admin[0].id }
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "admin" {
  count = local.admin_gate_enabled ? 1 : 0

  zone_id = cloudflare_zone.this.id
  name    = var.admin_gate_subdomain
  type    = "A"
  content = var.admin_gate_origin_ip
  proxied = true
  ttl     = 1
}

resource "gitlab_project_variable" "admin_gate_ops" {
  for_each = local.admin_gate_ops_vars

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
