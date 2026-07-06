module "github_mirror" {
  source   = "../github_repository"
  for_each = local.mirror_repositories

  name         = each.key
  description  = each.value.description
  homepage_url = coalesce(try(each.value.github.homepage_url, ""), "https://${var.domain}")
  topics       = each.value.topics

  has_issues              = try(each.value.github.has_issues, true)
  has_wiki                = try(each.value.github.has_wiki, true)
  has_projects            = try(each.value.github.has_projects, true)
  delete_branch_on_merge  = try(each.value.github.delete_branch_on_merge, false)
  vulnerability_alerts    = try(each.value.github.vulnerability_alerts, false)
  auto_init               = try(each.value.github.auto_init, false)
  gitignore_template      = try(each.value.github.gitignore_template, null)
  license_template        = try(each.value.github.license_template, null)
  enforce_admins          = try(each.value.github.enforce_admins, true)
  required_linear_history = try(each.value.github.required_linear_history, false)
  allows_force_pushes     = try(each.value.github.allows_force_pushes, false)

  enable_branch_protection = false
}
