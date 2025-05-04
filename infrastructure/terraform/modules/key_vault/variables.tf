variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "aks_principal_id" {
  description = "Principal ID of the AKS cluster managed identity"
  type        = string
}

variable "db_password" {
  description = "Database password to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret key to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}