resource "tls_private_key" "bootstrap" {
  algorithm = "ED25519"
}

resource "tls_private_key" "deploy" {
  algorithm = "ED25519"
}

module "host" {
  source = "../prod_host"

  count = var.enable ? 1 : 0

  name           = var.name
  ssh_public_key = tls_private_key.bootstrap.public_key_openssh
  plan           = var.plan
  data_center_id = var.data_center_id
  template_id    = var.template_id
}

# Public IPv4 of the host, consumed by the provision job (inventory) and DNS.
# Scope "*" (not "production"): the IP is not a secret (the protection is
# protected=true), and a job without environment: production (e.g. the runner
# provisioner that uses it as the Tang allowlist) must still see it.
resource "gitlab_project_variable" "host_ip" {
  count             = var.enable ? 1 : 0
  project           = var.ops_project_id
  key               = "PROD_HOST_IP"
  value             = module.host[0].vps_ipv4
  masked            = false
  protected         = true
  environment_scope = "*"
}

resource "gitlab_project_variable" "ansible_ssh_key" {
  project           = var.ops_project_id
  key               = "PROD_ANSIBLE_SSH_PRIVATE_KEY"
  value             = tls_private_key.bootstrap.private_key_openssh
  variable_type     = "file"
  masked            = false
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "deploy_public_key" {
  project           = var.ops_project_id
  key               = "DEPLOY_SSH_PUBLIC_KEY"
  value             = tls_private_key.deploy.public_key_openssh
  masked            = false
  protected         = true
  environment_scope = "production"
}

# Break-glass passphrase (LUKS fallback keyslot). Deliberately a placeholder
# with ignore_changes: a Terraform-generated value would live forever in the
# state backend, defeating a key meant to survive an online infra compromise.
# The operator sets the real value out of band once for bootstrap and removes
# it afterward (pg_luks only needs it on the first run).
resource "gitlab_project_variable" "luks_breakglass" {
  project           = var.ops_project_id
  key               = "PROD_LUKS_BREAKGLASS"
  value             = "placeholder"
  masked            = true
  protected         = true
  environment_scope = "production"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "gitlab_project_variable" "luks_tang_thp" {
  project           = var.ops_project_id
  key               = "PROD_LUKS_TANG_THP"
  value             = var.tang_thumbprint
  masked            = false
  protected         = true
  environment_scope = "production"
}
