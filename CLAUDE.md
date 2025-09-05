# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository demonstrates HashiCorp Vault configuration management using Terraform, implementing Infrastructure as Code principles for stateful security services. The project showcases enterprise-grade patterns for managing Vault policies, authentication methods, PKI infrastructure, and application secrets across multiple environments.

## Architecture

### Core Components
- **Main Configuration**: `main.tf` contains super-user policies and GitHub auth backend configuration
- **Terraform Modules**: 
  - `applications` module: Creates KV v2 mounts and policies per application/environment
  - `vault_namespace` module: Manages Vault namespaces with admin tokens and policies
- **Identity Management**: YAML-driven identity configuration with Python validation scripts
- **PKI Infrastructure**: Certificate authority setup and role management for machine/human identities
- **Authentication Backends**: GitHub OAuth, AWS IAM roles, and PKI-based authentication

### Key Terraform Files
- `versions.tf`: Provider versions (Terraform ~1.10.0, Vault ~5.1.0, TLS ~4.0.6)
- `variables.tf`: Required variables include `vault_url` and `environment`
- `data.tf`: Data sources for dynamic configuration
- `provider.tf`: Vault provider configuration
- `backend-local.tf`: Terraform state backend configuration

## Development Commands

### Infrastructure Management
```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file=dev.tfvars

# Apply configuration
terraform apply -var-file=dev.tfvars

# Validate configuration
terraform validate

# Format code
terraform fmt
```

### Pre-commit Hooks
The repository uses pre-commit hooks for code quality:
- `terraform_fmt`: Format Terraform code
- `terraform_tflint`: Lint Terraform code
- `terraform_trivy`: Security scanning
- `terraform_validate`: Validate Terraform configuration

Run manually with:
```bash
pre-commit run --all-files
```

### Identity Validation
Validate YAML identity configurations:
```bash
cd identities
python3 validate_identities.py
```

### Local Development Environment
Start Vault Enterprise container:
```bash
docker compose up -d
```

The container runs on `http://localhost:8200` with root token `dev-root-token`.

## Important Patterns

### Module Usage
- Applications are provisioned via the `applications` module with environment-specific KV mounts
- Namespaces follow the pattern: `module.vault_namespace` for tenant isolation
- Each application gets separate secret-provider and secret-consumer policies

### Policy Management
- Super-user policy provides broad Vault administration capabilities
- Application policies follow least-privilege with separate read/write permissions
- Namespace admin policies enable delegated administration

### Authentication Flow
- GitHub OAuth for human users (requires HashiCorp organization membership)
- AWS IAM roles for service authentication
- PKI certificates for machine identity verification
- Token rotation configured for 30-day cycles

### Environment Variables
Required for Vault Enterprise:
- `VAULT_LICENSE`: Enterprise license key
- Vault connection details configured in `dev.tfvars`

## Testing and Validation

The repository includes validation scripts for identity configurations and uses Terraform's built-in validation. All infrastructure changes should be planned and reviewed before applying to prevent service disruption.