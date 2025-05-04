kubernetes_version = "1.27.7"
location = "eastus2"

node_count = {
  dev  = 1
  test = 2
  prod = 3
}

node_size = {
  dev  = "Standard_D2s_v3"
  test = "Standard_D2s_v3"
  prod = "Standard_D4s_v3"
}

default_tags = {
  Project     = "Book Library"
  ManagedBy   = "Terraform"
  Application = "Book Library API"
  Environment = "Test"
}