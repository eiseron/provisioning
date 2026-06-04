resource "gitlab_project" "this" {
  name             = var.name
  description      = var.description
  visibility_level = var.visibility_level
  namespace_id     = var.namespace_id

  topics = var.topics

  issues_access_level                   = var.issues_access_level
  wiki_access_level                     = var.wiki_access_level
  remove_source_branch_after_merge      = true
  squash_option                         = "always"
  merge_method                          = "ff"
  initialize_with_readme                = true
  only_allow_merge_if_pipeline_succeeds = var.only_allow_merge_if_pipeline_succeeds
  build_timeout                         = var.build_timeout
  ci_separated_caches                   = var.ci_separated_caches

  auto_cancel_pending_pipelines                    = "enabled"
  auto_devops_enabled                              = false
  only_allow_merge_if_all_discussions_are_resolved = true
  resolve_outdated_diff_discussions                = true
  ci_pipeline_variables_minimum_override_role      = "maintainer"

  avatar      = var.avatar_path
  avatar_hash = var.avatar_path == null ? null : filesha256(var.avatar_path)

  squash_commit_template = <<-EOT
    %%{title}

    %%{all_commits}

    %%{co_authored_by}
  EOT

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [initialize_with_readme]
  }
}

resource "gitlab_branch_protection" "main" {
  project            = gitlab_project.this.id
  branch             = "main"
  push_access_level  = var.push_access_level
  merge_access_level = "maintainer"
  allow_force_push   = false
}

resource "gitlab_tag_protection" "version" {
  project             = gitlab_project.this.id
  tag                 = "*"
  create_access_level = var.tag_create_access_level
}
