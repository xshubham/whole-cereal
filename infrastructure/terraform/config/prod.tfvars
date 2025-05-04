environment = "prod"
location    = "eastus2"

# Resource Group
resource_group_name = "book-library"

# AKS Configuration
cluster_name        = "book-library-aks"
kubernetes_version  = "1.27.7"

# System Node Pool
node_count         = 3
node_count_min     = 3
node_count_max     = 5
node_size          = "Standard_D4s_v3"

# Application Node Pool
app_node_count     = 4
app_node_count_min = 4
app_node_count_max = 10
app_node_size      = "Standard_D8s_v3"

# Networking
vnet_cidr           = "10.3.0.0/16"
aks_subnet_cidr     = "10.3.0.0/20"
db_subnet_cidr      = "10.3.16.0/24"
gateway_subnet_cidr = "10.3.32.0/24"

# Monitoring
log_analytics_workspace_name = "book-library-logs"
retention_days = 90
cpu_threshold = 75
memory_threshold = 75
pod_readiness_threshold = 95
ops_email = "ops-team@yourdomain.com"

# Key Vault
key_vault_name = "book-library-kv"
allowed_ip_ranges = []  # Restrict to VNet access only

# Security
enable_pod_security_policy = true
enable_network_policy = true

default_tags = {
  Project     = "Book Library"
  ManagedBy   = "Terraform"
  Application = "Book Library API"
  Environment = "Production"
  Team        = "DevOps"
  Cost_Center = "Production"
  Criticality = "High"
  Compliance  = "PCI-DSS"
}