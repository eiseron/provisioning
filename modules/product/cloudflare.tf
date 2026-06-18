data "cloudflare_api_token_permission_groups_list" "all" {}

locals {
  perm_groups = data.cloudflare_api_token_permission_groups_list.all.result

  cfl_account_perm = {
    for g in local.perm_groups : g.name => g.id
    if contains(g.scopes, "com.cloudflare.api.account")
  }

  cfl_zone_perm = {
    for g in local.perm_groups : g.name => g.id
    if contains(g.scopes, "com.cloudflare.api.account.zone")
  }

  zone_settings = {
    always_use_https         = "on"
    ssl                      = "strict"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
    brotli                   = "on"
  }
}

resource "cloudflare_zone" "this" {
  name = var.domain
  account = {
    id = var.cloudflare_account_id
  }
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings

  zone_id    = cloudflare_zone.this.id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_r2_bucket" "state" {
  account_id = var.cloudflare_account_id
  name       = "${var.slug}-terraform-state"
  location   = var.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_account_token" "ops_write" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - ${title(var.slug)} Ops (Terraform)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        for id in sort([for name, gid in local.cfl_zone_perm : gid]) : { id = id }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${cloudflare_zone.this.id}" = "*"
      })
    },
    {
      effect = "allow"
      permission_groups = [
        for id in sort([
          local.cfl_account_perm["Workers R2 Storage Write"],
          local.cfl_account_perm["Pages Write"],
          local.cfl_account_perm["Workers Scripts Write"],
          local.cfl_account_perm["Workers KV Storage Write"],
        ]) : { id = id }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
      })
    }
  ]
}

resource "cloudflare_account_token" "ops_readonly" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - ${title(var.slug)} Ops Readonly (Terraform)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        for id in sort([for name, gid in local.cfl_zone_perm : gid if endswith(name, " Read")]) : { id = id }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${cloudflare_zone.this.id}" = "*"
      })
    },
    {
      effect = "allow"
      permission_groups = [
        for id in sort([
          local.cfl_account_perm["Workers R2 Storage Read"],
          local.cfl_account_perm["Pages Read"],
          local.cfl_account_perm["Workers Scripts Read"],
          local.cfl_account_perm["Workers KV Storage Read"],
        ]) : { id = id }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
      })
    }
  ]
}

resource "cloudflare_api_token" "state_write" {
  name = "Service Token - ${title(var.slug)} TF state (R2 write)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = local.cfl_account_perm["Workers R2 Storage Write"] },
      ]
      resources = jsonencode({
        "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.state.name}" = "*"
      })
    }
  ]
}

resource "cloudflare_api_token" "state_readonly" {
  name = "Service Token - ${title(var.slug)} TF state (R2 readonly)"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = local.cfl_account_perm["Workers R2 Storage Read"] },
      ]
      resources = jsonencode({
        "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.state.name}" = "*"
      })
    }
  ]
}

resource "cloudflare_dns_record" "apex" {
  count = var.apex_target == null ? 0 : 1

  zone_id = cloudflare_zone.this.id
  name    = var.domain
  type    = "A"
  content = var.apex_target
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "preview_wildcard" {
  count = var.preview_host_ip == null ? 0 : 1

  zone_id = cloudflare_zone.this.id
  name    = "*"
  type    = "A"
  content = var.preview_host_ip
  proxied = true
  ttl     = 1
}
