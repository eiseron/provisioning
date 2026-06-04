resource "github_repository" "this" {
  name        = var.name
  description = var.description

  visibility   = var.visibility
  homepage_url = var.homepage_url

  has_issues   = var.has_issues
  has_wiki     = var.has_wiki
  has_projects = var.has_projects

  delete_branch_on_merge = var.delete_branch_on_merge
  vulnerability_alerts   = var.vulnerability_alerts

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template

  allow_merge_commit = var.allow_merge_commit
  allow_squash_merge = var.allow_squash_merge
  allow_rebase_merge = var.allow_rebase_merge

  topics = var.topics
}

resource "github_branch_protection" "main" {
  count = var.enable_branch_protection ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = "main"

  enforce_admins          = var.enforce_admins
  required_linear_history = var.required_linear_history
  allows_force_pushes     = var.allows_force_pushes
  allows_deletions        = var.allows_deletions
}
