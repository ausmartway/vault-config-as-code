# Devcontainer for Vault Config-as-Code

This directory contains the development container configuration for the
vault-config-as-code project. The devcontainer provides a complete, isolated
development environment with Vault Enterprise, Terraform, and all necessary
tooling pre-configured.

## Quick Start

### Prerequisites

1. **Docker Desktop** (or Docker Engine) installed and running
2. **VS Code** with the [Dev Containers extension](
   https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. **Vault Enterprise License** - Set in `.env` file (see
   [Environment Setup](#environment-setup))

### Opening in Devcontainer

#### VS Code

1. Clone the repository
2. Open the project in VS Code
3. Press `F1` and select "Dev Containers: Reopen in Container"
4. Wait for the container to build and start (first time takes a few minutes)

#### Claude Code

If you open this repository in Claude Code, it will automatically detect and
use the devcontainer configuration.

### What Happens Automatically

When the devcontainer starts:

1. **Vault Enterprise** starts as a companion service on port 8200
2. **Terraform** initializes with required providers
3. **Pre-commit hooks** are installed for code quality checks
4. **Environment variables** are configured for Vault and Terraform
5. **VS Code extensions** are installed automatically

## Environment Setup

### Required Variables

Create a `.env` file in the project root (this file is already in
`.gitignore`):

```bash
# Vault Enterprise License (required for Vault Enterprise features)
VAULT_LICENSE=your-vault-license-key-here
```

### Optional Variables

You can set these in your local environment or in `.env`:

```bash
# Timezone (default: Australia/Sydney)
TZ=Australia/Sydney

# Terraform Cloud/Enterprise Token (for private modules)
TFE_TOKEN=your-tfe-token
```

## Architecture

### Container Services

The devcontainer uses Docker Compose to orchestrate two services:

```text
┌─────────────────────────────────────┐
│   Dev Container (app)               │
│   - ausmartway/vault-devcontainer   │
│   - Terraform tooling               │
│   - VS Code extensions              │
│   - Workspace mounted               │
└──────────────┬──────────────────────┘
               │ localhost:8200
               ↓
┌─────────────────────────────────────┐
│   Vault Enterprise (vault-dev)      │
│   - hashicorp/vault-enterprise      │
│   - Port 8200 exposed               │
│   - Dev mode with root token        │
└─────────────────────────────────────┘
```

### Building and publishing the image

From the repository root (Docker Hub user must match the image namespace):

```bash
docker build -t ausmartway/vault-devcontainer:latest \
  -f .devcontainer/vault-devcontainer/Dockerfile \
  .devcontainer/vault-devcontainer
docker push ausmartway/vault-devcontainer:latest
```

### Network Configuration

- **Host Network Mode**: `--network=host` allows the devcontainer to access
  Vault via `localhost:8200`
- **Bridge Network**: Services communicate via `vault-network` bridge network
- **Port Forwarding**: Vault UI is accessible at `http://localhost:8200/ui`

### Development Workflow

```bash
# Vault is already running with root token: dev-root-token

# View Vault status
vault status

# List secrets engines
vault secrets list

# Plan Terraform changes
terraform plan -var-file=dev.tfvars

# Apply Terraform changes
terraform apply -var-file=dev.tfvars

# Run pre-commit hooks manually
pre-commit run --all-files
```

## Pre-installed Tools

The devcontainer includes the following tools:

### Core Tools

- **Terraform** - Infrastructure as Code
- **Vault** - HashiCorp Vault Enterprise CLI
- **tflint** - Terraform linter
- **trivy** - Security scanner
- **pre-commit** - Git hook framework

### VS Code Extensions

- `hashicorp.terraform` - Terraform language support
- `HashiCorp.HCL` - HCL syntax highlighting
- `redhat.vscode-yaml` - YAML validation and formatting
- `anthropic.claude-code` - Claude Code integration

### Additional Tools

- **jq** - JSON processor for parsing API responses
- **curl** - HTTP client for testing API endpoints
- **git** - Version control
- **bash/zsh** - Shell environments

## Configuration Files

### Directory Structure

```text
.devcontainer/
├── docker-compose.devcontainer.yml    # Service orchestration
├── vault-devcontainer/
│   ├── Dockerfile                      # Container image definition
│   ├── devcontainer.json              # Devcontainer configuration
│   └── scripts/
│       ├── post-create.sh             # Post-creation setup
│       ├── vault-init.sh              # Vault health check
│       └── pre-commit-setup.sh        # Pre-commit installation
└── README.md                          # This file
```

### Customization

#### Adding VS Code Extensions

Edit `vault-devcontainer/devcontainer.json`:

```json
"extensions": [
  "hashicorp.terraform",
  "your.extension.here"
]
```

#### Adding Environment Variables

Edit `vault-devcontainer/devcontainer.json`:

```json
"remoteEnv": {
  "YOUR_VAR": "value"
}
```

#### Modifying Vault Configuration

Edit `docker-compose.devcontainer.yml` to change Vault settings:

```yaml
vault-dev:
  environment:
    VAULT_DEV_ROOT_TOKEN_ID: "your-token"
```

## Troubleshooting

### Vault Not Starting

**Symptom**: Post-create script fails with "Vault did not become ready"

**Solutions**:

1. Check that `.env` file contains `VAULT_LICENSE`
2. Verify Docker Desktop is running
3. Check Vault container logs: `docker logs vault-dev-enterprise`
4. Restart containers: "Dev Containers: Rebuild Container"

### Terraform Init Fails

**Symptom**: "Error initializing Terraform"

**Solutions**:

1. Check internet connectivity (required for provider downloads)
2. Verify `dev.tfvars` exists and contains valid variables
3. Try manual init: `terraform init -upgrade`

### Pre-commit Hooks Not Running

**Symptom**: Git commits don't trigger pre-commit checks

**Solutions**:

1. Verify hooks are installed: `ls -la .git/hooks/pre-commit`
2. Install manually: `pre-commit install`
3. Run manually: `pre-commit run --all-files`

### Permission Issues

**Symptom**: "Permission denied" errors

**Solutions**:

1. Ensure you're running as the `node` user (default in devcontainer)
2. Check file permissions: `ls -la` in workspace
3. Rebuild container: "Dev Containers: Rebuild Container"

### Port Already in Use

**Symptom**: "Port 8200 already in use"

**Solutions**:

1. Stop existing Vault containers: `docker stop vault-dev-enterprise`
2. Check for other processes on port 8200: `lsof -i :8200`
3. Modify port in `docker-compose.devcontainer.yml` if needed

## Development Tips

### Vault UI Access

Access the Vault UI at: `http://localhost:8200/ui`

- Token: `dev-root-token`
- No authentication required in dev mode

### Terraform State

Terraform state is stored locally in `terraform.tfstate`
(not recommended for production).

### Git Workflow

The devcontainer includes pre-commit hooks that:

- Format Terraform files (`terraform fmt`)
- Run tflint for best practices
- Scan with Trivy for security issues
- Validate Terraform configuration

### Performance

For better performance:

1. Use Docker Desktop with sufficient resources (4+ GB RAM, 2+ CPUs)
2. Store workspace on SSD (not network drive)
3. Use `.git/info/exclude` for large generated files

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Project architecture and development guide
- [Terraform Documentation](https://www.terraform.io/docs)
- [Vault Documentation](https://www.vaultproject.io/docs)
- [Dev Containers Documentation](
  https://code.visualstudio.com/docs/devcontainers/containers)

## Support

For issues or questions:

1. Check this README's troubleshooting section
2. Review `.devcontainer/vault-devcontainer/scripts/post-create.sh` logs
3. Check container logs: `docker logs vault-dev-enterprise`
4. Consult project CLAUDE.md for architecture details
