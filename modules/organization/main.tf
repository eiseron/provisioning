resource "gitlab_group" "this" {
  name             = var.name
  path             = var.slug
  description      = var.group.description
  visibility_level = var.group.visibility_level

  avatar      = var.avatar_path
  avatar_hash = var.avatar_path == null ? null : filesha256(var.avatar_path)

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  default_repos = {
    "${var.slug}-ops" = {
      description                           = "Infrastructure as Code of the Organization"
      visibility_level                      = "private"
      topics                                = []
      issues_access_level                   = "enabled"
      wiki_access_level                     = "disabled"
      squash_option                         = "never"
      only_allow_merge_if_pipeline_succeeds = true
      deploy_promotion                      = true
    }
    "${var.slug}-site" = {
      description                           = "Institutional Website of the Organization"
      visibility_level                      = "private"
      topics                                = []
      issues_access_level                   = "enabled"
      wiki_access_level                     = "disabled"
      squash_option                         = "always"
      only_allow_merge_if_pipeline_succeeds = true
      deploy_promotion                      = false
      protect_release_branch                = true
    }
    "${var.slug}-planning" = {
      description                           = "Implementation Plans and Architecture of the Organization"
      visibility_level                      = "private"
      topics                                = []
      issues_access_level                   = "enabled"
      wiki_access_level                     = "disabled"
      squash_option                         = "always"
      only_allow_merge_if_pipeline_succeeds = false
      deploy_promotion                      = false
      protect_release_branch                = true
    }
  }
  effective_repos = {
    for k, v in merge(local.default_repos, var.repos) : k => v
    if !contains(tolist(var.skip_repos), k)
  }
  site_preview_enabled = var.site_preview.site_project_id != ""
}

resource "gitlab_group_membership" "robot" {
  count        = var.robot_user_id != null ? 1 : 0
  group_id     = gitlab_group.this.id
  user_id      = var.robot_user_id
  access_level = "developer"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group_service_account" "robot" {
  count    = var.service_account != null ? 1 : 0
  group    = gitlab_group.this.id
  name     = var.service_account.name
  username = var.service_account.username

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group_membership" "service_account" {
  count        = var.service_account != null ? 1 : 0
  group_id     = gitlab_group.this.id
  user_id      = gitlab_group_service_account.robot[0].service_account_id
  access_level = "developer"

  lifecycle {
    prevent_destroy = true
  }
}

module "repo" {
  for_each = local.effective_repos
  source   = "../gitlab_repository_protected"

  name                                  = each.key
  description                           = each.value.description
  namespace_id                          = gitlab_group.this.id
  visibility_level                      = each.value.visibility_level
  topics                                = each.value.topics
  issues_access_level                   = each.value.issues_access_level
  wiki_access_level                     = each.value.wiki_access_level
  squash_option                         = each.value.squash_option
  only_allow_merge_if_pipeline_succeeds = each.value.only_allow_merge_if_pipeline_succeeds
  deploy_promotion                      = each.value.deploy_promotion
  protect_release_branch                = each.value.protect_release_branch
  avatar_path                           = var.avatar_path
}

module "site_preview" {
  count  = local.site_preview_enabled ? 1 : 0
  source = "../pages_preview"

  ops_project_id     = var.ops_project_id
  ops_project_path   = var.ops_project_path
  site_project_id    = var.site_preview.site_project_id
  site_project_path  = var.site_preview.site_project_path
  pages_project_name = var.site_preview.pages_project_name
}
