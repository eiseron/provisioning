locals {
  _group_id_num = local.resolved_group_id != "" ? tonumber(local.resolved_group_id) : 0
  _manage_repos = var.manage_repos && local._group_id_num != 0

  _extra_cfgs = var.repositories

  _homepage_url = var.domain != "" ? "https://${var.domain}" : ""

  _app_project_id    = local._manage_repos ? tostring(module.gl_app_repo[0].id) : var.app_project_id
  _app_project_path  = local._manage_repos ? module.gl_app_repo[0].path_with_namespace : var.app_project_path
  _site_project_id   = local._manage_repos ? tostring(module.gl_site_repo[0].id) : var.site_preview.site_project_id
  _site_project_path = local._manage_repos ? module.gl_site_repo[0].path_with_namespace : var.site_preview.site_project_path
}

module "gl_app_repo" {
  count  = local._manage_repos ? 1 : 0
  source = "../gitlab_repository_protected"

  name                   = var.slug
  description            = var.description
  namespace_id           = local._group_id_num
  visibility_level       = "private"
  topics                 = var.topics
  issues_access_level    = "enabled"
  wiki_access_level      = "disabled"
  initialize_with_readme = true
  shared_runners_enabled = false
}

module "gl_site_repo" {
  count  = local._manage_repos ? 1 : 0
  source = "../gitlab_repository"

  name                     = "${var.slug}-site"
  description              = var.description
  namespace_id             = local._group_id_num
  visibility_level         = "private"
  topics                   = []
  issues_access_level      = "enabled"
  wiki_access_level        = "disabled"
  initialize_with_readme   = true
  push_access_level        = "maintainer"
  protect_release_branches = false
}

module "gl_planning_repo" {
  count  = local._manage_repos ? 1 : 0
  source = "../gitlab_repository"

  name                                  = "${var.slug}-planning"
  description                           = var.description
  namespace_id                          = local._group_id_num
  visibility_level                      = "private"
  issues_access_level                   = "enabled"
  only_allow_merge_if_pipeline_succeeds = false
  initialize_with_readme                = true
  protect_release_branches              = false
}

module "gh_app_repo" {
  count  = local._manage_repos ? 1 : 0
  source = "../github_repository_protected"

  name                    = var.slug
  description             = var.description
  homepage_url            = local._homepage_url
  topics                  = var.topics
  has_wiki                = false
  has_projects            = true
  delete_branch_on_merge  = true
  vulnerability_alerts    = true
  required_linear_history = true
}

module "gh_site_repo" {
  count  = local._manage_repos ? 1 : 0
  source = "../github_repository"

  name                     = "${var.slug}-site"
  description              = var.description
  homepage_url             = local._homepage_url
  topics                   = []
  has_wiki                 = false
  has_projects             = false
  delete_branch_on_merge   = true
  vulnerability_alerts     = true
  enable_branch_protection = false
}

module "gl_extra_repos" {
  for_each = local._manage_repos ? local._extra_cfgs : {}
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
  for_each = local._manage_repos ? { for k, v in local._extra_cfgs : k => v if v.github != null } : {}
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
