# Infrastructure as Code Repository

This repository contains the Infrastructure as Code (IaC) for the Book Library application using Terraform. It follows GitOps principles with infrastructure deployments managed through Jenkins pipelines.

## Prerequisites

- Azure CLI
- Terraform >= 1.0
- Jenkins with required plugins:
  - Azure Credentials
  - Terraform
  - Pipeline
  - Email Extension

## Repository Structure

```
infrastructure/
├── terraform/
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   ├── dev.tfvars        # Development environment variables
│   ├── test.tfvars       # Test environment variables
│   └── prod.tfvars       # Production environment variables
└── Jenkinsfile           # CI/CD pipeline definition
```

## Infrastructure Components

- Azure Resource Group
- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)
- Azure Key Vault
- Log Analytics Workspace with Container Insights
- Storage Account for Terraform state

## Jenkins Pipeline Workflow

1. **Init**: Initialize Terraform and select workspace
2. **Format Check**: Ensure Terraform files are properly formatted
3. **Validate**: Validate Terraform configuration
4. **Plan**: Generate and show execution plan
5. **Review**: Manual approval required for production
6. **Apply**: Apply the Terraform plan
7. **Verify**: Verify the deployed infrastructure

## Environment Management

The infrastructure is managed in three environments:
- Development (dev)
- Testing (test)
- Production (prod)

Each environment has its own:
- Terraform workspace
- Variable definitions (.tfvars)
- Resource configurations
- Access controls

## Usage

### Jenkins Pipeline Parameters

- **WORKSPACE**: Select environment (dev/test/prod)
- **DESTROY**: Option to destroy infrastructure (use with caution)

### Required Jenkins Credentials

Set up the following credentials in Jenkins:
- azure-subscription-id
- azure-client-id
- azure-client-secret
- azure-tenant-id

### Manual Deployment

If needed, you can deploy manually:

```bash
# Initialize
terraform init -backend-config=backend.tfvars

# Select workspace
terraform workspace select dev  # or test/prod

# Plan
terraform plan -var-file=dev.tfvars  # or test.tfvars/prod.tfvars

# Apply
terraform apply
```

## GitOps Workflow

1. Create a feature branch
2. Make infrastructure changes
3. Create a pull request
4. Review and approve changes
5. Merge to main branch
6. Jenkins pipeline automatically:
   - Deploys to dev
   - Runs verification
   - Promotes to test (after approval)
   - Promotes to prod (after approval)

## Best Practices

1. Always use version control
2. Review all changes before applying
3. Use consistent naming conventions
4. Tag all resources appropriately
5. Use workspace-specific variables
6. Keep sensitive data in Key Vault
7. Use least-privilege access
8. Regular state backup and versioning

## Security Considerations

- All sensitive values are stored in Azure Key Vault
- Production changes require manual approval
- RBAC is enabled on AKS
- Network policies are enforced
- Regular security scanning enabled