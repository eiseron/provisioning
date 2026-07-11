terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.45"
    }
  }
}

provider "hcloud" {}

variable "server_type" {
  type    = string
  default = "cpx21"
}

variable "location" {
  type    = string
  default = "ash"
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}

variable "deploy_ssh_authorized_key" {
  type = string
}

variable "k3s_version" {
  type    = string
  default = "v1.30.5+k3s1"
}

variable "luks" {
  type = object({
    device = optional(string, "/dev/sdb")
    name   = optional(string, "crypt")
    mount  = optional(string, "/var/lib/crypt")
    wipe   = optional(bool, true)
    tang = optional(object({
      url        = optional(string, "")
      thumbprint = optional(string, "")
    }), {})
  })
  default = {}
}

module "spike" {
  source = "../.."

  name                      = "coreos-spike"
  server_type               = var.server_type
  location                  = var.location
  ssh_public_key            = var.ssh_public_key
  ssh_private_key           = var.ssh_private_key
  deploy_ssh_authorized_key = var.deploy_ssh_authorized_key

  luks = var.luks

  k3s = {
    enable  = true
    version = var.k3s_version
  }
}

output "ipv4" {
  value = module.spike.vps_ipv4
}
