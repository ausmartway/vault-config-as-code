# Self-contained Vault config-as-code devcontainer.
# Published as: ausmartway/vault-devcontainer:latest
FROM mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm

# Switch to root to install system packages
USER root

ARG TERRAFORM_VERSION=1.11.4
ARG TFLINT_VERSION=0.55.1
ARG VAULT_VERSION=1.21.3
ARG TRIVY_VERSION=0.72.0

# Install additional tools for Vault development
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    wget \
    unzip \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Detect architecture once for HashiCorp / Aqua downloads
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        arm64|aarch64) HC_ARCH=arm64; TRIVY_ARCH=ARM64 ;; \
        amd64|x86_64)  HC_ARCH=amd64; TRIVY_ARCH=64bit ;; \
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    echo "Building for ARCH=${ARCH} HC_ARCH=${HC_ARCH}" && \
    # Terraform
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${HC_ARCH}.zip" && \
    unzip -o "terraform_${TERRAFORM_VERSION}_linux_${HC_ARCH}.zip" -d /usr/local/bin && \
    rm "terraform_${TERRAFORM_VERSION}_linux_${HC_ARCH}.zip" && \
    chmod +x /usr/local/bin/terraform && \
    # Vault CLI
    wget -q "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${HC_ARCH}.zip" && \
    unzip -o "vault_${VAULT_VERSION}_linux_${HC_ARCH}.zip" -d /usr/local/bin && \
    rm "vault_${VAULT_VERSION}_linux_${HC_ARCH}.zip" && \
    chmod +x /usr/local/bin/vault && \
    # tflint
    wget -q "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${HC_ARCH}.zip" && \
    unzip -o "tflint_linux_${HC_ARCH}.zip" -d /usr/local/bin && \
    rm "tflint_linux_${HC_ARCH}.zip" && \
    chmod +x /usr/local/bin/tflint && \
    # trivy
    wget -q "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" && \
    tar -xzf "trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" -C /usr/local/bin trivy && \
    rm "trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" && \
    chmod +x /usr/local/bin/trivy

# pre-commit (used by post-create hooks)
RUN pip3 install --no-cache-dir --break-system-packages pre-commit

# Install Claude Code CLI and status line
RUN npm install -g @anthropic-ai/claude-code ccstatusline && \
    npm cache clean --force

# Create Claude configuration directory and configure status line for node user
RUN mkdir -p /home/node/.claude && \
    echo '{"statusLine":{"type":"command","command":"/bin/bash ~/.claude/statusline-command.sh","timeout":5000,"padding":0}}' > /home/node/.claude/settings.json && \
    mkdir -p /home/node/.config/ccstatusline && \
    chown -R node:node /home/node/.claude /home/node/.config/ccstatusline

# Configure ccstatusline with Powerline enabled
RUN echo '{\
  "version": 3,\
  "lines": [\
    [\
      {\
        "id": "1",\
        "type": "model",\
        "color": "cyan"\
      },\
      {\
        "id": "2",\
        "type": "separator"\
      },\
      {\
        "id": "3",\
        "type": "context-length",\
        "color": "brightBlack"\
      },\
      {\
        "id": "4",\
        "type": "separator"\
      },\
      {\
        "id": "5",\
        "type": "git-branch",\
        "color": "magenta"\
      },\
      {\
        "id": "6",\
        "type": "separator"\
      },\
      {\
        "id": "7",\
        "type": "git-changes",\
        "color": "yellow"\
      }\
    ],\
    [],\
    []\
  ],\
  "flexMode": "full-minus-40",\
  "compactThreshold": 60,\
  "colorLevel": 2,\
  "inheritSeparatorColors": false,\
  "globalBold": false,\
  "powerline": {\
    "enabled": true,\
    "separators": [\
      ""\
    ],\
    "separatorInvertBackground": [\
      false\
    ],\
    "startCaps": [""],\
    "endCaps": [""],\
    "autoAlign": true,\
    "theme": "gruvbox"\
  },\
  "defaultPadding": "     "\
}' > /home/node/.config/ccstatusline/settings.json && \
    chown node:node /home/node/.config/ccstatusline/settings.json

# Verify tools are available
RUN terraform version && tflint --version && vault --version && \
    trivy --version && pre-commit --version

# Switch to node user
USER node
WORKDIR /home/node
