#!/bin/bash

# Script for managing Terraform state operations

function show_usage() {
    echo "Usage: $0 <command> [environment]"
    echo "Commands:"
    echo "  backup  - Create a backup of the current state"
    echo "  clean   - Remove local Terraform files"
    echo "  list    - List resources in current state"
    echo "  import  - Import existing resources into state"
    echo "  remove  - Remove resource from state"
    echo "Environments: dev, test, prod"
}

function validate_env() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|test|prod)$ ]]; then
        echo "Error: Invalid environment. Must be dev, test, or prod"
        exit 1
    fi
}

if [ -z "$1" ]; then
    show_usage
    exit 1
fi

COMMAND=$1
ENV=${2:-dev}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
BACKUP_DIR="$ROOT_DIR/state-backups/$ENV"
STATE_KEY="terraform.tfstate.d/$ENV/terraform.tfstate"

validate_env "$ENV"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

case "$COMMAND" in
    backup)
        # Backup the current state
        cd "$ROOT_DIR"
        terraform workspace select $ENV
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        terraform state pull > "$BACKUP_DIR/${ENV}_${TIMESTAMP}.tfstate"
        # Create checksum
        sha256sum "$BACKUP_DIR/${ENV}_${TIMESTAMP}.tfstate" > "$BACKUP_DIR/${ENV}_${TIMESTAMP}.tfstate.sha256"
        echo "State backup created: ${ENV}_${TIMESTAMP}.tfstate"
        echo "Checksum file created: ${ENV}_${TIMESTAMP}.tfstate.sha256"
        ;;
        
    clean)
        # Clean local Terraform files
        cd "$ROOT_DIR"
        read -p "Are you sure you want to clean local Terraform files? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf .terraform/
            rm -f .terraform.lock.hcl
            rm -f terraform.tfstate*
            rm -f tfplan
            echo "Local Terraform files cleaned"
        fi
        ;;
        
    list)
        # List resources in state
        cd "$ROOT_DIR"
        terraform workspace select $ENV
        echo "Resources in $ENV environment:"
        terraform state list
        ;;
        
    import)
        # Import existing resource into state
        if [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: $0 import <environment> <resource_address> <resource_id>"
            exit 1
        fi
        cd "$ROOT_DIR"
        terraform workspace select $ENV
        terraform import "$3" "$4"
        ;;
        
    remove)
        # Remove resource from state
        if [ -z "$3" ]; then
            echo "Usage: $0 remove <environment> <resource_address>"
            exit 1
        fi
        cd "$ROOT_DIR"
        terraform workspace select $ENV
        read -p "Are you sure you want to remove $3 from state? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform state rm "$3"
        fi
        ;;
        
    *)
        echo "Invalid command: $COMMAND"
        show_usage
        exit 1
        ;;
esac