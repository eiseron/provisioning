terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/validate-only"
}

module "k3s_platform" {
  source = "../.."

  providers = {
    kubernetes = kubernetes
  }

  enable                   = true
  acme_email               = "ops@example.test"
  acme_domains             = ["example.test"]
  cloudflare_dns_api_token = "validate-only-placeholder"
  acme_use_staging         = true
}
