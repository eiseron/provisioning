locals {
  _group_id_num = var.group_id != "" ? tonumber(var.group_id) : 0

  _app_cfg      = try(var.repositories["app"], null)
  _site_cfg     = try(var.repositories["site"], null)
  _planning_cfg = try(var.repositories["planning"], null)
  _extra_cfgs   = { for k, v in var.repositories : k => v if !contains(["app", "site", "planning"], k) }

  _app_project_id    = local._app_cfg != null ? tostring(module.gl_app_repo[0].id) : var.app_project_id
  _app_project_path  = local._app_cfg != null ? module.gl_app_repo[0].path_with_namespace : var.app_project_path
  _site_project_id   = local._site_cfg != null ? tostring(module.gl_site_repo[0].id) : var.site_preview.site_project_id
  _site_project_path = local._site_cfg != null ? module.gl_site_repo[0].path_with_namespace : var.site_preview.site_project_path
}

module "gl_app_repo" {
  count  = local._app_cfg != null ? 1 : 0
  source = "../gitlab_repository_protected"

  name                   = var.slug
  description            = try(local._app_cfg.description, "")
  namespace_id           = local._group_id_num
  visibility_level       = "private"
  topics                 = try(local._app_cfg.topics, [])
  issues_access_level    = "enabled"
  wiki_access_level      = "disabled"
  initialize_with_readme = true
  shared_runners_enabled = false
}

module "gl_site_repo" {
  count  = local._site_cfg != null ? 1 : 0
  source = "../gitlab_repository"

  name                     = "${var.slug}-site"
  description              = try(local._site_cfg.description, "")
  namespace_id             = local._group_id_num
  visibility_level         = "private"
  topics                   = try(local._site_cfg.topics, [])
  issues_access_level      = "enabled"
  wiki_access_level        = "disabled"
  initialize_with_readme   = true
  push_access_level        = try(local._site_cfg.push_access_level, "maintainer")
  protect_release_branches = false
}

module "gl_planning_repo" {
  count  = local._planning_cfg != null ? 1 : 0
  source = "../gitlab_repository"

  name                                  = "${var.slug}-planning"
  description                           = try(local._planning_cfg.description, "")
  namespace_id                          = local._group_id_num
  visibility_level                      = "private"
  issues_access_level                   = "enabled"
  only_allow_merge_if_pipeline_succeeds = false
  initialize_with_readme                = true
  protect_release_branches              = false
}

module "gh_app_repo" {
  count  = local._app_cfg != null && try(local._app_cfg.github, null) != null ? 1 : 0
  source = "../github_repository_protected"

  name                    = var.slug
  description             = try(local._app_cfg.description, "")
  homepage_url            = try(local._app_cfg.github.homepage_url, "")
  topics                  = try(local._app_cfg.topics, [])
  has_wiki                = false
  has_projects            = try(local._app_cfg.github.has_projects, false)
  delete_branch_on_merge  = true
  vulnerability_alerts    = true
  required_linear_history = true
}

module "gh_site_repo" {
  count  = local._site_cfg != null && try(local._site_cfg.github, null) != null ? 1 : 0
  source = "../github_repository"

  name                     = "${var.slug}-site"
  description              = try(local._site_cfg.description, "")
  homepage_url             = try(local._site_cfg.github.homepage_url, "")
  topics                   = try(local._site_cfg.topics, [])
  has_wiki                 = false
  has_projects             = false
  delete_branch_on_merge   = true
  vulnerability_alerts     = true
  enable_branch_protection = false
}

module "gl_extra_repos" {
  for_each = local._extra_cfgs
  source   = "../gitlab_repository"

  name                     = "${var.slug}-${each.key}"
  description              = each.value.description
  namespace_id             = local._group_id_num
  visibility_level         = each.value.visibility_level
  topics                   = each.value.topics
  issues_access_level      = "enabled"
  wiki_access_level        = "disabled"
  initialize_with_readme   = true
  push_access_level        = each.value.push_access_level
  protect_release_branches = false
}

module "gh_extra_repos" {
  for_each = { for k, v in local._extra_cfgs : k => v if v.github != null }
  source   = "../github_repository"

  name                     = "${var.slug}-${each.key}"
  description              = each.value.description
  homepage_url             = try(each.value.github.homepage_url, "")
  topics                   = each.value.topics
  has_wiki                 = false
  has_projects             = try(each.value.github.has_projects, false)
  delete_branch_on_merge   = true
  vulnerability_alerts     = true
  enable_branch_protection = false
}
