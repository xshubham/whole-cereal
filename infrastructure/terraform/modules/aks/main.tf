resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size            = var.node_size
    enable_auto_scaling = true
    min_count          = var.node_count_min
    max_count          = var.node_count_max
    os_disk_size_gb    = 50
    type               = "VirtualMachineScaleSets"
    zones              = var.environment == "prod" ? ["1", "2", "3"] : null

    upgrade_settings {
      max_surge = "33%"
    }

    tags = merge(var.default_tags, {
      Environment = var.environment
      NodePool    = "system"
    })
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled    = true
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
    outbound_type     = "loadBalancer"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  microsoft_defender {
    enabled = var.environment == "prod" ? true : false
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3]
    }
    not_allowed {
      start = "2025-01-01T00:00:00Z"
      end   = "2025-01-02T00:00:00Z"
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    max_graceful_termination_sec    = 600
    scale_down_delay_after_add      = "10m"
    scale_down_delay_after_failure  = "3m"
    scale_down_unneeded             = "10m"
    scale_down_unready              = "20m"
    scale_down_utilization_threshold = 0.5
  }

  dynamic "auto_scaler_profile" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      balance_similar_node_groups      = true
      expander                        = "random"
      max_graceful_termination_sec    = 600
      max_node_provisioning_time      = "15m"
      max_unready_nodes               = 3
      max_unready_percentage          = 45
      new_pod_scale_up_delay         = "10s"
      scale_down_delay_after_add     = "10m"
      scale_down_delay_after_delete  = "10s"
      scale_down_delay_after_failure = "3m"
      scan_interval                  = "10s"
      scale_down_unneeded            = "10m"
      scale_down_unready             = "20m"
      scale_down_utilization_threshold = 0.5
    }
  }

  ingress_application_gateway {
    enabled   = true
    gateway_name = "${var.cluster_name}-appgw"
    subnet_id = var.gateway_subnet_id
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      frequency   = "Weekly"
      interval    = 1
      duration    = "PT4H"
      day_of_week = "Sunday"
      start_time  = "00:00"
    }
  }

  workload_identity_enabled = true
  oidc_issuer_enabled      = true

  azure_policy_enabled = var.environment == "prod" ? true : false

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size              = var.app_node_size
  node_count           = var.app_node_count
  
  enable_auto_scaling   = true
  min_count            = var.app_node_count_min
  max_count            = var.app_node_count_max
  
  zones                = var.environment == "prod" ? ["1", "2", "3"] : null
  os_disk_size_gb      = 50
  
  node_taints = [
    "workload=application:NoSchedule"
  ]
  
  node_labels = {
    "nodepool"    = "application"
    "environment" = var.environment
    "workload"    = "application"
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
    NodePool    = "application"
  })
}