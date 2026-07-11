terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.45"
    }
  }
}

provider "hcloud" {
  token = "0000000000000000000000000000000000000000000000000000000000000000"
}

module "coreos_host" {
  source = "../.."

  name                      = "acme-app-green"
  server_type               = "cpx21"
  location                  = "ash"
  ssh_public_key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVALIDATEonly admin@ci"
  ssh_private_key           = "validate-only-placeholder"
  deploy_ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVALIDATEonly deploy@ci"
}
