variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "book-library"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "book-library-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27.7"
}

variable "node_count" {
  description = "Default number of nodes per environment"
  type        = map(number)
  default = {
    dev  = 1
    test = 2
    prod = 3
  }
}

variable "node_count_min" {
  description = "Minimum number of nodes per environment"
  type        = map(number)
  default = {
    dev  = 1
    test = 2
    prod = 3
  }
}

variable "node_count_max" {
  description = "Maximum number of nodes per environment"
  type        = map(number)
  default = {
    dev  = 3
    test = 4
    prod = 10
  }
}

variable "node_size" {
  description = "VM size for nodes per environment"
  type        = map(string)
  default = {
    dev  = "Standard_D2s_v3"
    test = "Standard_D2s_v3"
    prod = "Standard_D4s_v3"
  }
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
  default     = "book-library-logs"
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "book-library-kv"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Project     = "Book Library"
    ManagedBy   = "Terraform"
    Application = "Book Library API"
  }
}