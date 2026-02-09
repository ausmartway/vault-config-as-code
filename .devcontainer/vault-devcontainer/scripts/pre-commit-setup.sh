#!/bin/bash
# Pre-commit setup script for devcontainer
set -e

echo "=== Pre-commit Setup ==="

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "✗ Error: pre-commit is not installed"
    echo "  Please ensure the base image includes pre-commit"
    exit 1
fi

echo "✓ pre-commit found: $(pre-commit --version)"

# Check if .pre-commit-config.yaml exists
if [ ! -f /workspace/.pre-commit-config.yaml ]; then
    echo "⚠ Warning: .pre-commit-config.yaml not found in workspace"
    echo "  Skipping pre-commit installation"
    exit 0
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
cd /workspace

if pre-commit install > /dev/null 2>&1; then
    echo "✓ Pre-commit hooks installed successfully"
else
    echo "✗ Error: Failed to install pre-commit hooks"
    exit 1
fi

# Validate pre-commit configuration
echo "Validating pre-commit configuration..."
if pre-commit validate-config > /dev/null 2>&1; then
    echo "✓ Pre-commit configuration is valid"
else
    echo "⚠ Warning: Pre-commit configuration validation failed"
fi

# Show installed hooks
echo ""
echo "Installed pre-commit hooks:"
pre-commit run --all-files --show-diff-on-failure --verbose || true

echo ""
echo "Pre-commit setup complete!"
