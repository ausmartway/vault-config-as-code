FROM hashiyulei/yulei-devcontainer:latest

# Switch to root to install system packages
USER root

# Install additional tools for Vault development
RUN apt-get update && apt-get install -y \
    jq \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Vault CLI (supports multi-arch via architecture detection)
RUN ARCH=$(dpkg --print-architecture) && \
    VAULT_VERSION="1.21.3" && \
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then \
        VAULT_ARCH="arm64"; \
    else \
        VAULT_ARCH="amd64"; \
    fi && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip && \
    unzip vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip -d /usr/local/bin && \
    rm vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip && \
    chmod +x /usr/local/bin/vault

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
RUN terraform version && tflint --version && vault --version

# Switch to node user
USER node
WORKDIR /home/node
