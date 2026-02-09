#!/bin/bash
# Vault initialization and health check script for devcontainer
set -e

echo "=== Vault Initialization ==="

# Configuration
VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200}
VAULT_TOKEN=${VAULT_TOKEN:-dev-root-token}
MAX_WAIT=60
WAIT_INTERVAL=2

export VAULT_ADDR VAULT_TOKEN

echo "Vault Address: $VAULT_ADDR"
echo "Waiting for Vault to be ready (max ${MAX_WAIT}s)..."

# Wait for Vault to be ready
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if curl -s -f "$VAULT_ADDR/v1/sys/health" > /dev/null 2>&1; then
        echo "✓ Vault is ready!"
        break
    fi

    if [ $elapsed -eq 0 ]; then
        echo -n "  Waiting"
    else
        echo -n "."
    fi

    sleep $WAIT_INTERVAL
    elapsed=$((elapsed + WAIT_INTERVAL))
done

echo ""

# Check if we timed out
if [ $elapsed -ge $MAX_WAIT ]; then
    echo "✗ Error: Vault did not become ready within ${MAX_WAIT}s"
    echo "  Please check that VAULT_LICENSE is set in .env file"
    exit 1
fi

# Verify Vault access
echo "Verifying Vault access..."
if vault status > /dev/null 2>&1; then
    echo "✓ Vault is accessible and initialized"
    echo ""
    echo "Vault Status:"
    echo "  Type: $(vault status -format=json | jq -r '.type')"
    echo "  Version: $(vault status -format=json | jq -r '.version')"
    echo "  HA: $(vault status -format=json | jq -r '.ha_enabled')"
    echo ""
    echo "Vault is ready for Terraform operations!"
else
    echo "✗ Error: Vault health check passed but status command failed"
    exit 1
fi

# Verify VAULT_LICENSE is set (fail fast if missing)
if [ -z "$VAULT_LICENSE" ]; then
    echo "⚠ Warning: VAULT_LICENSE environment variable is not set"
    echo "  Vault will run in development mode but may have limitations"
fi
