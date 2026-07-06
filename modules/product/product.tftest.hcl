mock_provider "gitlab" {}
mock_provider "cloudflare" {}
mock_provider "github" {}
mock_provider "tls" {}
mock_provider "random" {}

variables {
  slug                  = "myproduct"
  parent_group_id       = "123456"
  domain                = "myproduct.io"
  cloudflare_account_id = "b406da57022f7381e45749bddbee7f8a"
}

run "github_null_by_default_on_extra_repository" {
  command = plan

  variables {
    repositories = {
      "myproduct-site" = {
        description = "Site repo"
        topics      = ["website"]
        mirror      = true
      }
    }
  }

  assert {
    condition     = var.repositories["myproduct-site"].github == null
    error_message = "github sub-object must default to null when not provided"
  }
}

run "github_homepage_url_accepted_on_repository" {
  command = plan

  variables {
    repositories = {
      "myproduct-site" = {
        description = "Site repo"
        topics      = ["website"]
        mirror      = true
        github = {
          homepage_url = "https://myproduct.io"
        }
      }
    }
  }

  assert {
    condition     = var.repositories["myproduct-site"].github.homepage_url == "https://myproduct.io"
    error_message = "github.homepage_url must reflect the provided value"
  }
}

run "github_vulnerability_alerts_accepted" {
  command = plan

  variables {
    repositories = {
      "myproduct-site" = {
        description = "Site repo"
        topics      = ["website"]
        mirror      = true
        github = {
          vulnerability_alerts = true
        }
      }
    }
  }

  assert {
    condition     = var.repositories["myproduct-site"].github.vulnerability_alerts == true
    error_message = "github.vulnerability_alerts must reflect the provided value"
  }
}

run "github_gitignore_template_accepted" {
  command = plan

  variables {
    repositories = {
      "myproduct-site" = {
        description = "Site repo"
        topics      = ["website"]
        mirror      = true
        github = {
          gitignore_template = "Elixir"
        }
      }
    }
  }

  assert {
    condition     = var.repositories["myproduct-site"].github.gitignore_template == "Elixir"
    error_message = "github.gitignore_template must reflect the provided value"
  }
}
