resource "azurerm_log_analytics_workspace" "logs" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = var.environment == "prod" ? "PerGB2018" : "PerGB2018"
  retention_in_days   = lookup(var.retention_days, var.environment, 30)

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

# Storage account for diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                     = "diag${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version         = "TLS1_2"
  
  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

# Random suffix for storage account name
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Manage storage lifecycle policy
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.diagnostics.id

  rule {
    name    = "deleteOldLogs"
    enabled = true
    filters {
      blob_types = ["appendBlob"]
      prefix_match = ["insights-logs-"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = lookup(var.retention_days, var.environment, 30)
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_logs" {
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  log {
    category = "kube-apiserver"
    enabled  = true

    retention_policy {
      enabled = true
      days    = lookup(var.retention_days, var.environment, 30)
    }
  }

  log {
    category = "kube-audit"
    enabled  = true

    retention_policy {
      enabled = true
      days    = lookup(var.retention_days, var.environment, 30)
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = lookup(var.retention_days, var.environment, 30)
    }
  }
}

# Application Gateway Diagnostics
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "${var.environment}-appgw-diag"
  target_resource_id        = var.app_gateway_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = lookup(var.retention_days, var.environment, 30)
    }
  }
}

# Key Vault Diagnostics
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "${var.environment}-kv-diag"
  target_resource_id        = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = lookup(var.retention_days, var.environment, 30)
    }
  }
}

# Network Security Group Flow Logs
resource "azurerm_network_watcher_flow_log" "nsg_flows" {
  for_each = toset(var.nsg_ids)

  network_watcher_name = "NetworkWatcher_${var.location}"
  resource_group_name  = "NetworkWatcherRG"

  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.diagnostics.id
  enabled                  = true
  version                  = 2

  retention_policy {
    enabled = true
    days    = lookup(var.retention_days, var.environment, 30)
  }

  traffic_analytics {
    enabled               = var.environment == "prod" ? true : false
    workspace_id         = azurerm_log_analytics_workspace.logs.workspace_id
    workspace_region     = var.location
    workspace_resource_id = azurerm_log_analytics_workspace.logs.id
    interval_in_minutes  = var.environment == "prod" ? 10 : 60
  }
}

resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.environment}-critical-alerts"
  resource_group_name = var.resource_group_name
  short_name         = "critical"

  email_receiver {
    name          = "ops-team"
    email_address = var.ops_email
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
    Severity    = "Critical"
  })
}

resource "azurerm_monitor_metric_alert" "node_cpu" {
  name                = "${var.environment}-node-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Action will be triggered when CPU usage is above threshold"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = lookup(var.cpu_threshold, var.environment, 80)
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
    AlertType   = "CPU"
  })
}

resource "azurerm_monitor_metric_alert" "node_memory" {
  name                = "${var.environment}-node-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when memory usage is above threshold"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = lookup(var.memory_threshold, var.environment, 80)
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

resource "azurerm_monitor_metric_alert" "pod_readiness" {
  name                = "${var.environment}-pod-readiness-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when pod readiness is below threshold"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "pod_readiness_percentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = lookup(var.pod_readiness_threshold, var.environment, 90)
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  severity    = var.environment == "prod" ? 0 : 1
  frequency   = "PT5M"
  window_size = "PT15M"
}

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location             = var.location
  resource_group_name  = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.logs.id
  workspace_name       = azurerm_log_analytics_workspace.logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}