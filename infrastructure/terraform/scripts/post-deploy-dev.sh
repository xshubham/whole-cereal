#!/bin/bash

set -e

# Get cluster credentials
cluster_name=$(terraform output -raw aks_cluster_name)
resource_group=$(terraform output -raw resource_group_name)

echo "Running post-deployment validation for development environment..."

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$resource_group" \
    --name "$cluster_name" \
    --overwrite-existing

# Basic node pool validation
echo "Validating node pools..."
node_count=$(kubectl get nodes -l nodepool=application -o json | jq '.items | length')
if [ "$node_count" -lt 1 ]; then
    echo "Error: No application nodes found"
    exit 1
fi

# Check essential components
echo "Checking core components..."
for component in prometheus-server grafana; do
    if ! kubectl get deployment -n monitoring $component; then
        echo "Warning: $component not found in monitoring namespace"
    fi
done

# Validate Key Vault access
echo "Validating Key Vault access..."
if ! az keyvault secret list --vault-name "$cluster_name-kv" --query length -o tsv > /dev/null; then
    echo "Error: Unable to access Key Vault"
    exit 1
fi

# Check Application Gateway - less strict for dev
echo "Checking Application Gateway..."
gateway_name="${cluster_name}-appgw"
if ! az network application-gateway show \
    --name "$gateway_name" \
    --resource-group "$resource_group" \
    --query "name" \
    -o tsv > /dev/null; then
    echo "Error: Application Gateway not found"
    exit 1
fi

# Basic cluster health check
echo "Running basic health checks..."
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info

echo "Development post-deployment validation completed"