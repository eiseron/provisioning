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

module "k3s_app" {
  source = "../.."

  providers = {
    kubernetes = kubernetes
  }

  enable    = true
  name      = "app"
  namespace = "acme-app"
  image     = "registry.example.test/acme/app/prod:v1.0.0"
  app_host  = "app.example.test"

  env_clear = {
    PHX_HOST = "app.example.test"
    PORT     = "4000"
  }
  env_secret = {
    SECRET_KEY_BASE = "validate-only"
    DATABASE_URL    = "ecto://app:pw@platform-db-rw.platform/app_prod"
  }
}
