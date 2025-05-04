#!/bin/bash

set -e

function show_usage() {
    echo "Usage: $0 <environment> [--destroy]"
    echo "Environments: dev, test, prod"
    echo "Options:"
    echo "  --destroy    Destroy the infrastructure (requires confirmation)"
}

function validate_env() {
    if [[ ! "$1" =~ ^(dev|test|prod)$ ]]; then
        echo "Error: Invalid environment. Must be dev, test, or prod"
        exit 1
    fi

    # Additional validation for production
    if [ "$1" = "prod" ] && [ -z "$AZURE_DEVOPS_BUILD_ID" ]; then
        echo "Error: Production deployments must be run from Azure DevOps pipeline"
        exit 1
    fi
}

function check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check required tools
    local required_tools=("az" "terraform" "jq" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: $tool is not installed"
            exit 1
        fi
    done
    
    # Check Azure login status
    if ! az account show &> /dev/null; then
        echo "Error: Not logged into Azure. Please run 'az login'"
        exit 1
    fi

    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    if ! [[ "$tf_version" =~ ^1\. ]]; then
        echo "Error: Terraform version must be 1.x"
        exit 1
    fi

    # Check backend configuration
    if [ ! -f "backend.tfvars" ]; then
        echo "Error: backend.tfvars not found"
        exit 1
    fi
}

# Parse arguments
ENV=$1
DESTROY=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --destroy)
            DESTROY=true
            shift
            ;;
        --yes)
            SKIP_CONFIRM=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$ENV" ]; then
    show_usage
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$ROOT_DIR/config"
BACKUP_DIR="$ROOT_DIR/state-backups/$ENV"

validate_env "$ENV"
check_prerequisites

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting deployment for environment: $ENV"

# Backup current state if it exists
if [ -f "$ROOT_DIR/terraform.tfstate" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo "Creating state backup before deployment..."
    cp "$ROOT_DIR/terraform.tfstate" "$BACKUP_DIR/pre_deploy_${TIMESTAMP}.tfstate"
fi

# Initialize Terraform
cd "$ROOT_DIR"
echo "Initializing Terraform..."
terraform init -backend-config=backend.tfvars -reconfigure

# Select workspace
echo "Selecting workspace: $ENV"
terraform workspace select $ENV || terraform workspace new $ENV

if [ "$DESTROY" = true ]; then
    if [ "$ENV" = "prod" ]; then
        echo "DANGER! You are about to DESTROY the PRODUCTION environment!"
        echo "This action cannot be undone!"
        read -p "Type 'DESTROY-PROD' to confirm: " confirm
        if [ "$confirm" != "DESTROY-PROD" ]; then
            echo "Destruction cancelled"
            exit 1
        fi
    elif [ "$SKIP_CONFIRM" = false ]; then
        read -p "Are you sure you want to destroy the $ENV environment? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Destruction cancelled"
            exit 1
        fi
    fi
    
    echo "Destroying infrastructure in $ENV..."
    terraform destroy -var-file="$CONFIG_DIR/$ENV.tfvars" -auto-approve
    exit 0
fi

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check -recursive

# Plan with environment-specific variables
echo "Creating deployment plan..."
terraform plan \
    -var-file="$CONFIG_DIR/$ENV.tfvars" \
    -out=tfplan

# If this is production, prompt for confirmation
if [ "$ENV" = "prod" ] && [ "$SKIP_CONFIRM" = false ]; then
    echo "WARNING: You are about to deploy to PRODUCTION!"
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Apply the plan
echo "Applying configuration..."
terraform apply tfplan

# Verify deployment
echo "Verifying deployment..."
terraform output

# Run environment-specific post-deploy checks
if [ -f "$SCRIPT_DIR/post-deploy-${ENV}.sh" ]; then
    echo "Running post-deployment checks..."
    bash "$SCRIPT_DIR/post-deploy-${ENV}.sh"
fi

echo "Deployment to $ENV completed successfully"