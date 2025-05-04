environment = "test"
location    = "eastus2"

# Resource Group
resource_group_name = "book-library"

# AKS Configuration
cluster_name        = "book-library-aks"
kubernetes_version  = "1.27.7"

# System Node Pool
node_count         = 2
node_count_min     = 2
node_count_max     = 4
node_size          = "Standard_D2s_v3"

# Application Node Pool
app_node_count     = 2
app_node_count_min = 2
app_node_count_max = 6
app_node_size      = "Standard_D4s_v3"

# Networking
vnet_cidr           = "10.2.0.0/16"
aks_subnet_cidr     = "10.2.0.0/20"
db_subnet_cidr      = "10.2.16.0/24"
gateway_subnet_cidr = "10.2.32.0/24"

# Monitoring
log_analytics_workspace_name = "book-library-logs"
retention_days = 60
cpu_threshold = 80
memory_threshold = 80
pod_readiness_threshold = 90
ops_email = "test-team@yourdomain.com"

# Key Vault
key_vault_name = "book-library-kv"
allowed_ip_ranges = []  # Restrict to VNet access like production

# Security
enable_pod_security_policy = true  # Match production security
enable_network_policy = true

default_tags = {
  Project     = "Book Library"
  ManagedBy   = "Terraform"
  Application = "Book Library API"
  Environment = "Test"
  Team        = "DevOps"
  Cost_Center = "Test"
  Criticality = "Medium"
}