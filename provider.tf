terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.106.1"
    }
    spotinst = {
      source = "spotinst/spotinst"
      version = "1.204.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
  }
}

provider "azurerm" {
# use az account list in cli to get below details
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

#provider "kubectl" {
#  apply_retry_count      = 2
#  host                   = module.aks.host
#  client_certificate     = base64decode(module.aks.client_certificate)
#  client_key             = base64decode(module.aks.client_key)
#  cluster_ca_certificate = base64decode(module.aks.admin_client_certificate)
#  load_config_file       = false
#}
