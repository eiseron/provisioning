module "github_mirror" {
  source   = "../github_repository"
  for_each = local.mirror_repositories

  name         = each.key
  description  = each.value.description
  homepage_url = "https://${var.domain}"
  topics       = each.value.topics

  enable_branch_protection = false
}
