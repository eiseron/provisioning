locals {
  release_enabled = var.release_token != ""
}

resource "gitlab_project_variable" "release_token" {
  count             = local.release_enabled ? 1 : 0
  project           = local._app_project_path
  key               = "RELEASE_TOKEN"
  value             = var.release_token
  masked            = true
  protected         = true
  environment_scope = "*"
}

resource "gitlab_project_variable" "gitlab_token_docs" {
  count             = local.release_enabled ? 1 : 0
  project           = local._app_project_path
  key               = "GITLAB_TOKEN"
  value             = var.release_token
  masked            = true
  protected         = true
  environment_scope = "*"
}
