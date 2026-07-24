locals {
  group_token_vars = {
    for k, v in {
      GITHUB_TOKEN         = var.ci_vars.github_token
      GITLAB_TOKEN         = var.ci_vars.gitlab_token
      CLOUDFLARE_API_TOKEN = var.ci_vars.cloudflare_api_token
    } : k => v if nonsensitive(v != "") && nonsensitive(local.resolved_group_id != "")
  }

  cloudflare_account_id_set = nonsensitive(var.ci_vars.cloudflare_account_id != "") && nonsensitive(local.resolved_group_id != "")
  secrets_file_set          = nonsensitive(var.ci_vars.secrets_file != "")
}

resource "gitlab_group_variable" "ci_token" {
  for_each  = local.group_token_vars
  group     = local.resolved_group_id
  key       = each.key
  value     = each.value
  masked    = true
  protected = true
}

resource "gitlab_group_variable" "cloudflare_account_id" {
  count     = local.cloudflare_account_id_set ? 1 : 0
  group     = local.resolved_group_id
  key       = "CLOUDFLARE_ACCOUNT_ID"
  value     = var.ci_vars.cloudflare_account_id
  masked    = false
  protected = true
}

resource "gitlab_project_variable" "secrets_file" {
  count             = local.secrets_file_set ? 1 : 0
  project           = var.ops_project_id
  key               = "SECRETS_FILE"
  value             = var.ci_vars.secrets_file
  masked            = false
  protected         = true
  environment_scope = "production"
}
