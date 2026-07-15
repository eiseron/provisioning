terraform {
  required_version = ">= 1.9"

  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.30"
      configuration_aliases = [kubernetes]
    }
    helm = {
      source                = "hashicorp/helm"
      version               = ">= 2.13"
      configuration_aliases = [helm]
    }
    kubectl = {
      source                = "gavinbunney/kubectl"
      version               = ">= 1.14"
      configuration_aliases = [kubectl]
    }
  }
}
