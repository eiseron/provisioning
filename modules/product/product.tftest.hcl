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

run "media_outputs_are_null_when_media_disabled" {
  command = plan

  assert {
    condition     = output.media_public_base_url == null
    error_message = "media_public_base_url must be null when media_subdomain is unset"
  }

  assert {
    condition     = output.media_r2_bucket == null
    error_message = "media_r2_bucket must be null when media_subdomain is unset"
  }
}

run "media_outputs_derive_from_subdomain_when_enabled" {
  command = plan

  variables {
    media_subdomain = "img"
  }

  assert {
    condition     = output.media_r2_bucket == "myproduct-media"
    error_message = "media_r2_bucket must be <slug>-media so the runtime targets the product's own bucket"
  }

  assert {
    condition     = output.media_public_base_url == "https://img.myproduct.io"
    error_message = "media_public_base_url must be the media subdomain on the product domain so the app CSP and image URLs resolve"
  }

  assert {
    condition     = output.media_r2_endpoint == "https://b406da57022f7381e45749bddbee7f8a.r2.cloudflarestorage.com"
    error_message = "media_r2_endpoint must be the account's S3-compatible R2 endpoint"
  }
}
