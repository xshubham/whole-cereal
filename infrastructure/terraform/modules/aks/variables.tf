variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "node_count_min" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
}

variable "node_count_max" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 3
}

variable "node_size" {
  description = "VM size for nodes"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

variable "app_node_size" {
  description = "VM size for application nodes"
  type        = string
}

variable "app_node_count" {
  description = "Number of nodes in the application node pool"
  type        = number
}

variable "app_node_count_min" {
  description = "Minimum number of application nodes for autoscaling"
  type        = number
}

variable "app_node_count_max" {
  description = "Maximum number of application nodes for autoscaling"
  type        = number
}

variable "gateway_subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for container insights"
  type        = string
}