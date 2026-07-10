locals {
  _pages_project_name = var.site_preview.pages_project_name != "" ? var.site_preview.pages_project_name : "${var.slug}-site"
  _site_pages_enabled = try(var.site_repo.pages, null) != null && var.cloudflare_account_id != ""
  _site_pages_domains = local._site_pages_enabled ? try(var.site_repo.pages.domains, []) : []

  _extra_pages_repos = {
    for k, v in var.repositories : k => v
    if v.pages != null && var.cloudflare_account_id != ""
  }
  _extra_pages_domains = {
    for pair in flatten([
      for k, v in local._extra_pages_repos : [
        for domain in v.pages.domains : { key = "${k}:${domain}", repo = k, domain = domain }
      ]
    ]) : pair.key => pair
  }
}

resource "cloudflare_pages_project" "site" {
  count = local._site_pages_enabled ? 1 : 0

  account_id        = var.cloudflare_account_id
  name              = local._pages_project_name
  production_branch = try(var.site_repo.pages.production_branch, "main")
}

resource "cloudflare_pages_domain" "site" {
  for_each = toset(local._site_pages_domains)

  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.site[0].name
  name         = each.value
}

resource "cloudflare_pages_project" "extra" {
  for_each = local._extra_pages_repos

  account_id        = var.cloudflare_account_id
  name              = "${var.slug}-${each.key}"
  production_branch = try(each.value.pages.production_branch, "main")
}

resource "cloudflare_pages_domain" "extra" {
  for_each = local._extra_pages_domains

  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.extra[each.value.repo].name
  name         = each.value.domain
}
