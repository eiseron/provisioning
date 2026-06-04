resource "tls_private_key" "preview" {
  count     = var.preview_host_ip == null ? 0 : 1
  algorithm = "ED25519"
}

resource "random_password" "tenant" {
  count   = var.preview_host_ip == null ? 0 : 1
  length  = 40
  special = false
}

locals {
  preview_enabled = var.preview_host_ip != null

  preview_vars = local.preview_enabled ? {
    PREVIEW_HOST_IP = { value = var.preview_host_ip, masked = false, file = false }
    PREVIEW_ANSIBLE_SSH_PRIVATE_KEY = {
      value  = tls_private_key.preview[0].private_key_openssh
      masked = false
      file   = true
    }
    PREVIEW_TENANT_NAME     = { value = var.slug, masked = false, file = false }
    PREVIEW_TENANT_PASSWORD = { value = random_password.tenant[0].result, masked = true, file = false }
  } : {}
}

resource "gitlab_project_variable" "preview" {
  for_each = local.preview_vars

  project           = module.repository[local.ops_repo_key].id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = true
  environment_scope = "production"
  variable_type     = each.value.file ? "file" : "env_var"
}
