terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    container_name      = "tfstate"
    key                 = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Include base configuration
module "base" {
  source = "./base"
  
  resource_group_name           = var.resource_group_name
  location                      = var.location
  cluster_name                  = var.cluster_name
  kubernetes_version           = var.kubernetes_version
  node_count                   = var.node_count
  node_size                    = var.node_size
  log_analytics_workspace_name = var.log_analytics_workspace_name
  key_vault_name              = var.key_vault_name
  default_tags                = var.default_tags
}