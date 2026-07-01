data "cloudflare_api_token_permission_groups_list" "all" {}

locals {
  account_perm = {
    for group in data.cloudflare_api_token_permission_groups_list.all.result : group.name => group.id
    if contains(group.scopes, "com.cloudflare.api.account")
  }

  bucket_resource = "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.this.name}"
}

resource "cloudflare_r2_bucket" "this" {
  account_id = var.cloudflare_account_id
  name       = "${var.slug}-backups"
  location   = var.r2_location

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_account_token" "write" {
  account_id = var.cloudflare_account_id
  name       = "Service Token - ${title(var.slug)} DB backup (R2 write)"

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
