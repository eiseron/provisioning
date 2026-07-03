module "github_repo" {
  for_each = var.github_repos
  source   = "../github_repository_protected"

  name                     = each.key
  description              = each.value.description
  has_issues               = each.value.has_issues
  has_wiki                 = each.value.has_wiki
  has_projects             = each.value.has_projects
  auto_init                = each.value.auto_init
  license_template         = each.value.license_template
  allow_merge_commit       = each.value.allow_merge_commit
  allow_rebase_merge       = each.value.allow_rebase_merge
  vulnerability_alerts     = each.value.vulnerability_alerts
  topics                   = each.value.topics
  enable_branch_protection = each.value.enable_branch_protection
}
