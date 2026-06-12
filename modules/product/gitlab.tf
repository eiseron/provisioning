locals {
  is_public = var.visibility == "public"

  base_repositories = {
    (var.slug) = {
      description = var.description
      public      = local.is_public
      mirror      = local.is_public
      topics      = var.topics
      is_ops      = false
    }
    "${var.slug}-ops" = {
      description = "Infrastructure as Code for ${var.slug}"
      public      = false
      mirror      = false
      topics      = []
      is_ops      = true
    }
  }

  extra_repositories = {
    for key, repo in var.repositories : key => {
      description = repo.description
      public      = repo.is_ops ? false : repo.public
      mirror      = repo.is_ops ? false : coalesce(repo.mirror, repo.public)
      topics      = repo.topics
      is_ops      = repo.is_ops
    }
  }

  repositories = merge(local.base_repositories, local.extra_repositories)

  mirror_repositories = {
    for key, repo in local.repositories : key => repo if repo.mirror && !repo.is_ops
  }

  ops_repo_key = "${var.slug}-ops"
}

resource "gitlab_group" "this" {
  name             = var.slug
  path             = var.slug
  parent_id        = var.parent_group_id
  description      = var.description
  visibility_level = local.is_public ? "public" : "private"

  lifecycle {
    prevent_destroy = true
  }
}

module "repository" {
  source   = "../gitlab_repository_protected"
  for_each = local.repositories

  name                = each.key
  description         = each.value.description
  namespace_id        = gitlab_group.this.id
  visibility_level    = each.value.public ? "public" : "private"
  topics              = each.value.topics
  avatar_path         = var.avatar_path
  issues_access_level = "enabled"
  wiki_access_level   = "disabled"
}

resource "gitlab_group_service_account" "robot" {
  group    = var.parent_group_id
  name     = "${title(var.slug)} Robot"
  username = "${var.slug}_robot"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group_membership" "robot" {
  group_id     = gitlab_group.this.id
  user_id      = gitlab_group_service_account.robot.service_account_id
  access_level = "owner"
}

resource "gitlab_group_service_account_access_token" "robot_write" {
  group   = var.parent_group_id
  user_id = gitlab_group_service_account.robot.service_account_id
  name    = "${var.slug}-ops-write"
  scopes  = ["api"]

  rotation_configuration = {
    expiration_days    = 365
    rotate_before_days = 90
  }
}

resource "gitlab_group_service_account_access_token" "robot_readonly" {
  group   = var.parent_group_id
  user_id = gitlab_group_service_account.robot.service_account_id
  name    = "${var.slug}-ops-readonly"
  scopes  = ["read_api"]

  rotation_configuration = {
    expiration_days    = 365
    rotate_before_days = 90
  }
}

resource "gitlab_group_service_account" "ci" {
  group    = var.parent_group_id
  name     = "${title(var.slug)} CI"
  username = "${var.slug}_ci"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group_membership" "ci" {
  group_id     = gitlab_group.this.id
  user_id      = gitlab_group_service_account.ci.service_account_id
  access_level = "maintainer"
}

resource "gitlab_group_service_account_access_token" "ci" {
  group   = var.parent_group_id
  user_id = gitlab_group_service_account.ci.service_account_id
  name    = "${var.slug}-ci"
  scopes  = ["api"]

  rotation_configuration = {
    expiration_days    = 365
    rotate_before_days = 90
  }
}

resource "gitlab_project_push_mirror" "github" {
  for_each = local.mirror_repositories

  project = module.repository[each.key].id
  url     = "https://${var.github_owner}:${var.github_mirror_token}@github.com/${module.github_mirror[each.key].full_name}.git"
  enabled = true

  lifecycle {
    ignore_changes = [url]
  }
}
