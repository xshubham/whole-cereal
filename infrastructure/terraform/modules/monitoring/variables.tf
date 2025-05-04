variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_cluster_id" {
  description = "ID of the AKS cluster to monitor"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

variable "retention_days" {
  description = "Log retention days per environment"
  type        = map(number)
  default     = {
    dev  = 30
    test = 60
    prod = 90
  }
}

variable "cpu_threshold" {
  description = "CPU threshold percentage per environment"
  type        = map(number)
  default     = {
    dev  = 85
    test = 80
    prod = 75
  }
}

variable "memory_threshold" {
  description = "Memory threshold percentage per environment"
  type        = map(number)
  default     = {
    dev  = 85
    test = 80
    prod = 75
  }
}

variable "pod_readiness_threshold" {
  description = "Pod readiness threshold percentage per environment"
  type        = map(number)
  default     = {
    dev  = 85
    test = 90
    prod = 95
  }
}

variable "log_alert_frequency" {
  description = "Alert evaluation frequency per environment"
  type        = map(string)
  default     = {
    dev  = "PT15M"
    test = "PT10M"
    prod = "PT5M"
  }
}

variable "ops_email" {
  description = "Email address for operations team alerts"
  type        = string
  default     = "ops-team@yourdomain.com"
}

variable "app_gateway_id" {
  description = "Resource ID of the Application Gateway"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
}

variable "nsg_ids" {
  description = "List of Network Security Group IDs"
  type        = list(string)
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access diagnostic storage"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access diagnostic storage"
  type        = list(string)
  default     = []
}

variable "diagnostic_retention_days" {
  description = "Days to retain diagnostic logs per environment"
  type        = map(number)
  default     = {
    dev  = 30
    test = 60
    prod = 90
  }
}

variable "traffic_analytics_interval" {
  description = "NSG flow log analytics interval in minutes per environment"
  type        = map(number)
  default     = {
    dev  = 60
    test = 60
    prod = 10
  }
}