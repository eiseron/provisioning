resource "tls_private_key" "bootstrap" {
  algorithm = "ED25519"
}

resource "tls_private_key" "deploy" {
  algorithm = "ED25519"
}

resource "tls_private_key" "tang_bootstrap" {
  algorithm = "ED25519"
}

module "host" {
  source = "../prod_host"

  count = var.enable ? 1 : 0

  providers = {
    hcloud = hcloud.production
  }

  name           = var.name
  ssh_public_key = tls_private_key.bootstrap.public_key_openssh
  server_type    = var.server_type
  location       = var.location
  image          = var.image
}

module "tang" {
  source = "../tang_host"

  count = var.enable && var.encrypt_db ? 1 : 0

  providers = {
    hcloud = hcloud.keyserver
  }

  name           = "${var.name}-tang"
  server_type    = var.key_server_type
  location       = var.key_server_location
  ssh_public_key = tls_private_key.tang_bootstrap.public_key_openssh
}

module "observability" {
  source = "../observability"

  count = var.enable && var.observability_enable ? 1 : 0

  enable                = true
  zone_id               = var.zone_id
  zone_domain           = var.zone_domain
  prod_host_ip          = module.host[0].vps_ipv4
  ops_project_id        = var.ops_project_id
  cloudflare_account_id = var.cloudflare_account_id
  r2_location           = var.r2_location
  root_email            = var.observability_root_email
  root_password         = var.observability_root_password
  smtp_password         = var.observability_smtp_password
  smtp                  = var.observability_smtp
}

resource "gitlab_project_variable" "tang_host_ip" {
  count             = var.enable && var.encrypt_db ? 1 : 0
  project           = var.ops_project_id
  key               = "TANG_HOST_IP"
  value             = module.tang[0].vps_ipv4
  masked            = false
  protected         = true
  environment_scope = "*"
}

resource "gitlab_project_variable" "tang_ansible_ssh_key" {
  project           = var.ops_project_id
  key               = "TANG_ANSIBLE_SSH_PRIVATE_KEY"
  value             = tls_private_key.tang_bootstrap.private_key_openssh
  variable_type     = "file"
  masked            = false
  protected         = true
  environment_scope = "production"
}

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
  value             = var.key_server_thumbprint
  masked            = false
  protected         = true
  environment_scope = "production"
}
