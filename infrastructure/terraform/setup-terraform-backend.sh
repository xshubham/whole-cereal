#!/bin/bash

# Variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus2"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STORAGE_ACCOUNT_NAME \
    --sku Standard_LRS \
    --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --account-key $ACCOUNT_KEY

# Create backend config file
cat > backend.tfvars << EOF
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name      = "$CONTAINER_NAME"
key                = "terraform.tfstate"
resource_group_name = "$RESOURCE_GROUP_NAME"
EOF

echo "Storage account $STORAGE_ACCOUNT_NAME created successfully"
echo "Backend configuration saved to backend.tfvars"

# Initialize Terraform and create workspaces
terraform init
terraform workspace new dev
terraform workspace new test
terraform workspace new prod
terraform workspace select dev

echo "Terraform workspaces created: dev, test, prod"
echo "Currently on 'dev' workspace"