terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/validate-only"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/validate-only"
  }
}

provider "kubectl" {
  config_path = "~/.kube/validate-only"
}

module "k3s_postgres" {
  source = "../.."

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }

  enable             = true
  superuser_password = "validate-only-placeholder"

  backup = {
    enabled           = true
    endpoint_url      = "https://acct.r2.cloudflarestorage.com"
    destination_path  = "s3://acme-backups/platform-db"
    access_key_id     = "validate-only"
    secret_access_key = "validate-only"
  }

  seed = {
    enable            = true
    mode              = "streaming"
    host              = "app-external-db.internal"
    port              = 5432
    database          = "app"
    external_username = "app"
    external_password = "validate-only-placeholder"
  }
}
