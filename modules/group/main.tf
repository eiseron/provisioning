resource "gitlab_group" "this" {
  name             = var.name
  path             = var.slug
  parent_id        = var.parent_group_id
  description      = var.description
  visibility_level = var.visibility_level

  avatar      = var.avatar_path
  avatar_hash = var.avatar_path == null ? null : filesha256(var.avatar_path)

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  github_token_set        = nonsensitive(var.github_token != "")
  repos_with_github_token = local.github_token_set ? { for k, v in var.repos : k => v if v.publish_github_token } : {}
}

module "repo" {
  for_each    = var.repos
  source      = "../gitlab_repository"
  avatar_path = var.avatar_path

  name                = each.key
  description         = each.value.description
  namespace_id        = gitlab_group.this.id
  visibility_level    = each.value.visibility_level
  topics              = each.value.topics
  issues_access_level = each.value.issues_access_level
  wiki_access_level   = each.value.wiki_access_level
}

resource "gitlab_project_variable" "github_token" {
  for_each = local.repos_with_github_token

  project           = module.repo[each.key].id
  key               = "GITHUB_TOKEN"
  value             = var.github_token
  masked            = true
  protected         = true
  environment_scope = "*"
}
