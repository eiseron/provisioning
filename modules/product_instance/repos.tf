locals {
  _group_id_num = var.group_id != "" ? tonumber(var.group_id) : 0

  _extra_cfgs = var.repositories

  _app_project_id    = local._group_id_num != 0 ? tostring(module.gl_app_repo[0].id) : var.app_project_id
  _app_project_path  = local._group_id_num != 0 ? module.gl_app_repo[0].path_with_namespace : var.app_project_path
  _site_project_id   = local._group_id_num != 0 ? tostring(module.gl_site_repo[0].id) : var.site_preview.site_project_id
  _site_project_path = local._group_id_num != 0 ? module.gl_site_repo[0].path_with_namespace : var.site_preview.site_project_path
}

module "gl_app_repo" {
  count  = local._group_id_num != 0 ? 1 : 0
  source = "../gitlab_repository_protected"

  name                   = var.slug
  description            = var.repo.description
  namespace_id           = local._group_id_num
  visibility_level       = "private"
  topics                 = var.repo.topics
  issues_access_level    = "enabled"
  wiki_access_level      = "disabled"
  initialize_with_readme = true
  shared_runners_enabled = false
}

module "gl_site_repo" {
  count  = local._group_id_num != 0 ? 1 : 0
  source = "../gitlab_repository"

  name                     = "${var.slug}-site"
  description              = var.site_repo.description
  namespace_id             = local._group_id_num
  visibility_level         = "private"
  topics                   = var.site_repo.topics
  issues_access_level      = "enabled"
  wiki_access_level        = "disabled"
  initialize_with_readme   = true
  push_access_level        = var.site_repo.push_access_level
  protect_release_branches = false
}

module "gl_planning_repo" {
  count  = local._group_id_num != 0 ? 1 : 0
  source = "../gitlab_repository"

  name                                  = "${var.slug}-planning"
  description                           = var.planning_repo.description
  namespace_id                          = local._group_id_num
  visibility_level                      = "private"
  issues_access_level                   = "enabled"
  only_allow_merge_if_pipeline_succeeds = false
  initialize_with_readme                = true
  protect_release_branches              = false
}

module "gh_app_repo" {
  count  = local._group_id_num != 0 && var.repo.github != null ? 1 : 0
  source = "../github_repository_protected"

  name                    = var.slug
  description             = var.repo.description
  homepage_url            = try(var.repo.github.homepage_url, "")
  topics                  = var.repo.topics
  has_wiki                = false
  has_projects            = try(var.repo.github.has_projects, false)
  delete_branch_on_merge  = true
  vulnerability_alerts    = true
  required_linear_history = true
}

module "gh_site_repo" {
  count  = local._group_id_num != 0 && var.site_repo.github != null ? 1 : 0
  source = "../github_repository"

  name                     = "${var.slug}-site"
  description              = var.site_repo.description
  homepage_url             = try(var.site_repo.github.homepage_url, "")
  topics                   = var.site_repo.topics
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
