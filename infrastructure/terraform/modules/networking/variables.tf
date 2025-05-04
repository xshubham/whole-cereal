variable "environment" {
  description = "Environment name"
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

variable "vnet_cidr" {
  description = "CIDR block for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for AKS subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

variable "gateway_subnet_cidr" {
  description = "CIDR block for Application Gateway subnet"
  type        = string
}

variable "waf_rules" {
  description = "Additional WAF rules configuration"
  type = list(object({
    rule_group_name = string
    enabled         = bool
  }))
  default = []
}

variable "ssl_policy_min_protocol_version" {
  description = "Minimum version of the TLS protocol for SSL Policy"
  type        = string
  default     = "TLSv1_2"
}

variable "enable_http2" {
  description = "Enable HTTP2 for Application Gateway"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}

variable "allowed_dev_ip" {
  description = "IP address allowed for development access"
  type        = string
  default     = ""
}

variable "allowed_management_ips" {
  description = "List of IP addresses allowed for management access"
  type        = list(string)
  default     = []
}

variable "additional_waf_custom_rules" {
  description = "Additional custom WAF rules"
  type = list(object({
    name      = string
    priority  = number
    rule_type = string
    match_conditions = list(object({
      match_variables = list(object({
        variable_name = string
        selector     = string
      }))
      operator           = string
      negation_condition = bool
      match_values      = list(string)
    }))
    action = string
  }))
  default = []
}