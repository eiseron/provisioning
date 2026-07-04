locals {
  site_pages_enabled = (
    var.cloudflare_account_id != null &&
    local.site_preview_enabled &&
    var.site_preview.pages_project_name != ""
  )
  otp_idp_enabled = var.cloudflare_account_id != null
  _existing_otp_ids = local.otp_idp_enabled ? [
    for p in data.cloudflare_zero_trust_access_identity_providers.all[0].result : p.id
    if try(p.type, "") == "onetimepin"
  ] : []
  existing_otp_id = length(local._existing_otp_ids) > 0 ? local._existing_otp_ids[0] : null
}

data "cloudflare_zero_trust_access_identity_providers" "all" {
  count      = local.otp_idp_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
}

import {
  for_each = local.existing_otp_id != null ? { "0" = local.existing_otp_id } : {}
  to       = cloudflare_zero_trust_access_identity_provider.otp[0]
  id       = each.value
}

resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  count      = local.otp_idp_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = "One-time PIN"
  type       = "onetimepin"
  config     = {}

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = length(local._existing_otp_ids) <= 1
      error_message = "Found ${length(local._existing_otp_ids)} onetimepin identity providers in the account; expected at most 1."
    }
  }
}

resource "cloudflare_pages_project" "site" {
  count             = local.site_pages_enabled ? 1 : 0
  account_id        = var.cloudflare_account_id
  name              = var.site_preview.pages_project_name
  production_branch = "main"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_pages_domain" "site" {
  for_each     = local.site_pages_enabled ? toset(var.site_domains) : toset([])
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.site[0].name
  name         = each.key

  lifecycle {
    prevent_destroy = true
  }
}
