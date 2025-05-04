#!/bin/bash

set -e

# Get cluster credentials
cluster_name=$(terraform output -raw aks_cluster_name)
resource_group=$(terraform output -raw resource_group_name)

echo "Running post-deployment validation for test environment..."

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$resource_group" \
    --name "$cluster_name" \
    --overwrite-existing

# Validate node pool configuration
echo "Validating node pools..."
node_count=$(kubectl get nodes -l nodepool=application -o json | jq '.items | length')
if [ "$node_count" -lt 2 ]; then
    echo "Error: Expected at least 2 application nodes in test environment"
    exit 1
fi

# Check pod security policies - warn only in test
echo "Checking pod security policies..."
if ! kubectl auth can-i use podsecuritypolicy --all-namespaces; then
    echo "Warning: Pod security policies not enabled"
fi

# Validate network policies
echo "Validating network policies..."
if ! kubectl get networkpolicies --all-namespaces; then
    echo "Warning: Network policies not configured"
fi

# Check monitoring components
echo "Checking monitoring components..."
failed_components=0
for component in prometheus-server grafana loki-stack; do
    if ! kubectl get deployment -n monitoring $component; then
        echo "Error: $component not deployed"
        ((failed_components++))
    fi
done

if [ $failed_components -gt 0 ]; then
    echo "Error: Some monitoring components are missing"
    exit 1
fi

# Validate Key Vault integration
echo "Validating Key Vault integration..."
if ! az keyvault secret list --vault-name "$cluster_name-kv" --query length -o tsv > /dev/null; then
    echo "Error: Unable to access Key Vault"
    exit 1
fi

# Check Application Gateway health
echo "Checking Application Gateway health..."
gateway_name="${cluster_name}-appgw"
gateway_health=$(az network application-gateway show \
    --name "$gateway_name" \
    --resource-group "$resource_group" \
    --query "operationalState" \
    -o tsv)

if [ "$gateway_health" != "Running" ]; then
    echo "Error: Application Gateway not healthy. State: $gateway_health"
    exit 1
fi

# Validate WAF policy - Detection mode for test
echo "Checking WAF policy..."
waf_mode=$(az network application-gateway waf-policy list \
    --resource-group "$resource_group" \
    --query "[0].policySettings.mode" \
    -o tsv)

if [ "$waf_mode" != "Detection" ]; then
    echo "Warning: WAF not in Detection mode"
fi

# Check diagnostic settings
echo "Validating diagnostic settings..."
failed_diagnostics=0
components=("aks" "appgw" "keyvault")
for component in "${components[@]}"; do
    if ! az monitor diagnostic-settings list \
        --resource "$cluster_name-$component" \
        --resource-group "$resource_group" \
        --query "[?contains(name, 'diag')].id" \
        -o tsv > /dev/null; then
        echo "Warning: Diagnostic settings not configured for $component"
        ((failed_diagnostics++))
    fi
done

if [ $failed_diagnostics -gt 1 ]; then
    echo "Error: Multiple diagnostic settings missing"
    exit 1
fi

# Validate autoscaling configuration
echo "Checking autoscaling configuration..."
if ! kubectl get hpa --all-namespaces; then
    echo "Warning: No Horizontal Pod Autoscalers found"
fi

# Final health check
echo "Running final health checks..."
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
kubectl get events --sort-by='.lastTimestamp' | tail -n 10

echo "Test environment post-deployment validation completed"