locals {
  admin_gate_enabled = var.admin_gate_app_host != null
  admin_gate_uri     = var.admin_gate_app_host != null ? "${var.admin_gate_app_host}/admin" : null

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
      value  = var.admin_gate_app_host
      masked = false
      scope  = "production"
    }
  } : {}
}

resource "cloudflare_zero_trust_access_policy" "admin" {
  count = local.admin_gate_enabled ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = "${var.slug} admin"
  decision   = "allow"

  include = [for domain in var.admin_gate_email_domains : { email_domain = { domain = domain } }]

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = length(var.admin_gate_email_domains) > 0
      error_message = "admin_gate_email_domains must list at least one allowed email domain when the admin gate is enabled."
    }

    precondition {
      condition     = var.admin_gate_auth_domain != null
      error_message = "admin_gate_auth_domain is required when the admin gate is enabled."
    }

    precondition {
      condition     = var.admin_gate_app_host != null
      error_message = "admin_gate_app_host is required when the admin gate is enabled (the gate protects <app_host>/admin)."
    }
  }
}

resource "cloudflare_zero_trust_access_application" "admin" {
  count = local.admin_gate_enabled ? 1 : 0

  account_id                = var.cloudflare_account_id
  name                      = "${var.slug} admin"
  type                      = "self_hosted"
  session_duration          = "24h"
  app_launcher_visible      = false
  auto_redirect_to_identity = false

  destinations = [
    { type = "public", uri = local.admin_gate_uri },
  ]

  policies = [
    { id = cloudflare_zero_trust_access_policy.admin[0].id }
  ]

  lifecycle {
    prevent_destroy = true
  }
}

removed {
  from = cloudflare_dns_record.admin

  lifecycle {
    destroy = true
  }
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
