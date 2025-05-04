# Terraform Infrastructure Code

This directory contains the Terraform code for provisioning and managing the Book Library infrastructure in Azure.

## Directory Structure

```
terraform/
├── base/                  # Base infrastructure configuration
│   ├── main.tf           # Core resource definitions
│   └── outputs.tf        # Base module outputs
├── config/               # Environment-specific configurations
│   ├── dev.tfvars       # Development environment variables
│   ├── test.tfvars      # Testing environment variables
│   └── prod.tfvars      # Production environment variables
├── modules/              # Reusable Terraform modules
│   ├── aks/             # AKS cluster module
│   ├── acr/             # Container registry module
│   ├── monitoring/      # Monitoring and logging module
│   └── key_vault/       # Key Vault module
├── scripts/             # Utility scripts
│   ├── deploy.sh        # Deployment script
│   └── manage-state.sh  # State management utilities
├── main.tf              # Root configuration file
└── backend.tfvars       # Backend configuration (not in version control)
```

## Usage

### Environment Setup

1. Initialize the backend:
```bash
az login
./scripts/setup-terraform-backend.sh
```

2. Deploy to an environment:
```bash
./scripts/deploy.sh <environment>  # where environment is dev, test, or prod
```

### State Management

Use the state management script for various operations:
```bash
./scripts/manage-state.sh backup dev  # Create state backup for dev
./scripts/manage-state.sh list prod   # List resources in prod state
./scripts/manage-state.sh clean       # Clean local Terraform files
```

## Environment-Specific Configurations

- **Development**: Minimal resources, fast deployment
- **Testing**: Moderate resources, automated testing support
- **Production**: High availability, proper scaling

## Modules

### AKS Module
- Manages Azure Kubernetes Service clusters
- Includes autoscaling configuration
- Network policy and RBAC enabled

### ACR Module
- Manages Azure Container Registry
- Integrated with AKS

### Monitoring Module
- Sets up Log Analytics workspace
- Configures Container Insights
- Manages monitoring and alerting

### Key Vault Module
- Manages secrets and certificates
- Integrated with AKS and ACR

## Best Practices

1. Always use workspaces for environment isolation
2. Keep sensitive data in Key Vault
3. Use consistent naming conventions
4. Tag all resources appropriately
5. Regular state backups
6. Review changes before applying