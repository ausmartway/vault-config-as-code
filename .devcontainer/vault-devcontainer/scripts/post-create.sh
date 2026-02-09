#!/bin/bash
# Post-create setup script for Vault devcontainer
set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Vault Config-as-Code Devcontainer Setup                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Change to workspace directory
cd /workspace

# Step 1: Vault initialization
echo "[Step 1/4] Vault Initialization"
echo "────────────────────────────────────────"
if [ -f /workspace/.devcontainer/vault-devcontainer/scripts/vault-init.sh ]; then
    bash /workspace/.devcontainer/vault-devcontainer/scripts/vault-init.sh
    echo ""
else
    echo "✗ Error: vault-init.sh not found"
    exit 1
fi

# Step 2: Terraform initialization
echo "[Step 2/4] Terraform Initialization"
echo "────────────────────────────────────────"
if command -v terraform &> /dev/null; then
    echo "Initializing Terraform..."
    if terraform init -upgrade > /tmp/tf-init.log 2>&1; then
        echo "✓ Terraform initialized successfully"
        echo "  Providers: $(grep -o 'Downloading provider[^']*' /tmp/tf-init.log | sort -u | wc -l) downloaded"
    else
        echo "✗ Error: Terraform init failed. Check /tmp/tf-init.log"
        tail -n 20 /tmp/tf-init.log
        exit 1
    fi
else
    echo "✗ Error: terraform command not found"
    exit 1
fi
echo ""

# Step 3: Pre-commit setup
echo "[Step 3/4] Pre-commit Setup"
echo "────────────────────────────────────────"
if [ -f /workspace/.devcontainer/vault-devcontainer/scripts/pre-commit-setup.sh ]; then
    bash /workspace/.devcontainer/vault-devcontainer/scripts/pre-commit-setup.sh
    echo ""
else
    echo "⚠ Warning: pre-commit-setup.sh not found, skipping"
    echo ""
fi

# Step 4: Terraform validation
echo "[Step 4/4] Terraform Validation"
echo "────────────────────────────────────────"
if terraform validate > /dev/null 2>&1; then
    echo "✓ Terraform configuration is valid"
else
    echo "⚠ Warning: Terraform validation failed (this may be expected during initial setup)"
fi
echo ""

# Display welcome message
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Devcontainer Setup Complete!                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Quick Start Commands:"
echo "─────────────────────────────────────────────────────────────"
echo "  View Vault status:     vault status"
echo "  List Vault secrets:    vault secrets list"
echo "  Plan Terraform:        terraform plan -var-file=dev.tfvars"
echo "  Apply Terraform:       terraform apply -var-file=dev.tfvars"
echo "  Run pre-commit:        pre-commit run --all-files"
echo ""
echo "Environment Variables:"
echo "─────────────────────────────────────────────────────────────"
echo "  VAULT_ADDR=$VAULT_ADDR"
echo "  TF_VAR_vault_url=$TF_VAR_vault_url"
echo "  TF_VAR_environment=$TF_VAR_environment"
echo ""
echo "Documentation:"
echo "─────────────────────────────────────────────────────────────"
echo "  See .devcontainer/README.md for detailed usage instructions"
echo "  See CLAUDE.md for project architecture and development guide"
echo ""
