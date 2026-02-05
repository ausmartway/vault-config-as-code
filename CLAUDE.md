# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

HashiCorp Vault configuration management using Terraform. Implements IaC for
stateful security services with YAML-driven configuration for applications,
identities, PKI, and authentication.

## Git Branch Strategy

| Branch | Target Vault | Purpose |
|--------|--------------|---------|
| `main` | Production | Stable, production-ready configuration |
| `main-dev` | Local Docker | Development, validated before merge to main |
| `hcp` | HCP Vault Dedicated | HCP-specific configuration |
| `local` | Local Vault | Local development configuration |

**Development Workflow:** Validate and apply changes on `main-dev` against the
local Docker Vault, then merge to `main` for production deployment.

## Architecture

### YAML-Driven Configuration Pattern

The central architectural pattern uses `data.tf` to load YAML files from
configuration directories:

```text
YAML files → data.tf (fileset + yamldecode) → local.*_map → Terraform resources
```

Configuration directories (add YAML files here to provision resources):

- `applications/` - App KV mounts and policies
- `identities/` - Human (`human_*.yaml`) and application (`application_*.yaml`) identities
- `identity_groups/` - Hierarchical identity groupings
- `pkiroles/` - Certificate roles for machine/human IDs
- `pki-auth-roles/` - PKI authentication role mappings
- `awsauthroles/` - AWS IAM auth role bindings
- `namespaces/` - Multi-tenant namespace configs

Files named `example.yaml` in any directory are ignored.

### Key Terraform Files

- `main.tf` - Auth backends (GitHub, JWT, AWS, PKI, AppRole), secrets engines,
  super-user policy
- `data.tf` - YAML loading and transformation to Terraform maps
- `identities.tf` - Entity/alias creation from identity YAML
- `identity_groups.tf` - Group membership management
- `identity_token.tf` - OIDC token configuration with SPIFFE claims
- `applications.tf` - Uses `ausmartway/kv-for-application/vault` module

### Authentication Backends

| Backend | Purpose | Config Source |
|---------|---------|---------------|
| GitHub OAuth | Human users | `main.tf` |
| JWT (GitHub Actions) | CI/CD pipelines | `main.tf` |
| JWT (Terraform Cloud) | Infrastructure automation | `main.tf` |
| AWS IAM | Cloud services | `awsauthroles/*.yaml` |
| PKI Certificates | Machine identity | `pki-auth-roles/*.yaml` |
| AppRole | Application fallback | Per-app via module |

### PKI Infrastructure

Three-tier CA in `main.tf`:

- Root CA (`pki_root`) - 10-year TTL, self-signed
- Intermediate CA (`pki_intermediate`) - 2-year TTL, signs issued certs
- Alternative issuer - Redundancy/failover

### Identity Schema

Identities use JSON Schema validation (Draft 7):

- `identities/schema_human.yaml` - Human identity schema
- `identities/schema_application.yaml` - Application identity schema

Validate with: `cd identities && python3 validate_identities.py`

## Development Commands

```bash
# Start Vault Enterprise (requires VAULT_LICENSE in .env)
docker compose up -d

# Terraform workflow
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Code quality
pre-commit run --all-files
terraform fmt
terraform validate
```

Local Vault runs at `http://localhost:8200` with root token `dev-root-token`.

## Adding New Resources

### New Application

Create `applications/{appname}.yaml`:

```yaml
appid: MyApp
name: My Application
contact: owner@example.com
enable_approle: true
environments:
  - dev
  - production
```

### New Identity

Create `identities/human_{name}.yaml` or `identities/application_{name}.yaml`
following the schema.

### New PKI Role

Create `pkiroles/{rolename}.yaml` with allowed domains, TTLs, and certificate properties.

## Environment Variables

- `VAULT_LICENSE` - Enterprise license key (in `.env`, gitignored)
- Variables in `dev.tfvars`: `vault_url`, `environment`
