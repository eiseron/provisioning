mock_provider "gitlab" {
  mock_resource "gitlab_group" {
    defaults = {
      id = "999999"
    }
  }
}

variables {
  name             = "stack"
  slug             = "stack"
  parent_group_id  = "123456"
  description      = "Reusable engineering modules"
  visibility_level = "public"
  avatar_path      = null
  github_token     = "gh-token"

  repos = {
    "core" = {
      description = "Core lib"
      topics      = ["elixir"]
    }
    "public-image-bases" = {
      description          = "Base images"
      visibility_level     = "public"
      publish_github_token = false
    }
  }
}

run "creates_the_subgroup_and_every_repo" {
  command = plan

  assert {
    condition     = tostring(gitlab_group.this.parent_id) == "123456"
    error_message = "the subgroup must be created under parent_group_id"
  }

  assert {
    condition     = length(module.repo) == 2
    error_message = "one repo module instance must exist per entry in var.repos"
  }
}

run "github_token_is_published_only_for_repos_opted_in" {
  command = plan

  assert {
    condition     = contains(keys(gitlab_project_variable.github_token), "core")
    error_message = "core defaults publish_github_token = true and must get the CI variable"
  }

  assert {
    condition     = !contains(keys(gitlab_project_variable.github_token), "public-image-bases")
    error_message = "public-image-bases opted out of publish_github_token and must not get the CI variable"
  }
}

run "empty_github_token_skips_every_ci_variable" {
  command = plan

  variables {
    github_token = ""
  }

  assert {
    condition     = length(gitlab_project_variable.github_token) == 0
    error_message = "an empty github_token must skip the CI variable for every repo, regardless of publish_github_token"
  }
}
