################################################################################
# AUTHENTICATION BACKENDS
################################################################################

# GitHub OAuth Authentication
# Members of the HashiCorp organization can login to Vault using their personal
# GitHub token. This provides human user authentication with team-based access.
resource "vault_github_auth_backend" "hashicorp" {
  organization   = "hashicorp"
  token_ttl      = 3600 * 8      # 8 hours - balances security with user convenience
  token_max_ttl  = 3600 * 24 * 7 # 7 days - maximum session length before re-authentication
  token_policies = [""]
}

################################################################################
# TOKEN AUTO-ROTATION MECHANISM
################################################################################

# Token Auto-Rotation Mechanism
# - time_rotating triggers every 30 days
# - time_static captures the rotation timestamp
# - vault_token lifecycle replaces token when time_static changes
resource "vault_token" "superuser" {
  policies     = ["super-user"]
  display_name = "superuser"
  renewable    = true
  ttl          = "768h"
  metadata = {
    "purpose" = "service-account for terraform Cloud to manage vault"
  }
  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [time_static.rotate]
  }
}

resource "time_rotating" "rotate_30_days" {
  rotation_days = 30
}

resource "time_static" "rotate" {
  rfc3339 = time_rotating.rotate_30_days.rfc3339
}


################################################################################
# POLICIES
################################################################################

# Super user policy - full administrative access
resource "vault_policy" "super-user" {
  name   = "super-user"
  policy = <<EOF
# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Managing identity
path "identity/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Enable and manage the key/value secrets engine at `secret/` path
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# pki secrets engine
path "pki/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# pki_root secrets engine
path "pki_root/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

#pki_intermediate secrets engine
path "pki_intermediate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

#EaaS secrets engine
path "EaaS/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# aws secrets engine
path "aws/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ssh_client_signer secrets engine
path "ssh-client-signer/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow managing leases
path "sys/leases/*"
{
  capabilities = ["read", "update", "list"]
}

# Manage namespaces
path "sys/namespaces/*" {
   capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# For UI compatibility
path "sys/internal/ui/mounts" {
  capabilities = ["read"]
}

# Configure License
path "sys/license"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Configure Vault UI
path "sys/config/ui"
{
  capabilities = ["read", "update", "delete", "list"]
}
 EOF
}

################################################################################
# JWT AUTHENTICATION BACKENDS
################################################################################

# GitHub Actions JWT Authentication
# Enables GitHub Actions workflows to authenticate to Vault using OIDC tokens.
# This is the recommended way for CI/CD pipelines to access Vault secrets.
resource "vault_jwt_auth_backend" "github_repo_jwt" {
  description        = "jwt auth method for github repositories"
  type               = "jwt"
  path               = "github_repo_jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_jwt_auth_backend_role" "default" {
  backend         = vault_jwt_auth_backend.github_repo_jwt.path
  role_name       = "default"
  bound_audiences = ["eXVsZWkncyBWYXVsdAo="] # Base64 encoded value of "Yulie's Vault"
  user_claim      = "repository"
  role_type       = "jwt"
}

# Terraform Cloud JWT Authentication
# Enables Terraform Cloud workspaces to authenticate to Vault using workload identity.
resource "vault_jwt_auth_backend" "terraform_cloud" {
  description        = "jwt auth method for terraform cloud"
  type               = "jwt"
  path               = "terraform_cloud"
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
  default_role       = "tfc_default"
}

resource "vault_jwt_auth_backend_role" "tfc_default" {
  backend           = vault_jwt_auth_backend.terraform_cloud.path
  role_name         = "tfc_default"
  bound_audiences   = ["eXVsZWkncyBWYXVsdAo="]   # Base64 encoded value of "Yulie's Vault"
  user_claim        = "terraform_full_workspace" # Full workspace name: "organization:org_name:project:proj_name:workspace:ws_name"
  bound_claims_type = "glob"
  bound_claims      = { "terraform_organization_name" = "yulei" } # Terraform Cloud organization name
  role_type         = "jwt"
}

################################################################################
# AWS AUTHENTICATION & SECRETS ENGINE
################################################################################

# AWS IAM Authentication
# Enables AWS services to authenticate to Vault using their IAM credentials.
resource "vault_auth_backend" "aws" {
  type = "aws"
  path = "aws"
}

resource "vault_aws_auth_backend_client" "aws_client" {
  backend    = vault_auth_backend.aws.path
  access_key = ""
  secret_key = ""
}

resource "vault_aws_auth_backend_sts_role" "sts_role" {
  backend    = vault_auth_backend.aws.path
  account_id = "711129375688"
  sts_role   = "arn:aws:iam::711129375688:role/hcp-vault-auth"
}

# Azure Authentication (Disabled)
# Azure auth backend configuration is managed separately.
# Uncomment and configure when Azure integration is required.
# Note: Fix "tanent" typo to "tenant" when enabling.
# resource "vault_auth_backend" "azure" {
#   type = "azure"
#   path = "azure"
# }

# resource "vault_azure_auth_backend_config" "azure_auth_config" {
#   backend       = vault_auth_backend.azure.path
#   tenant_id     = var.azure_tanent_id
#   client_id     = var.azure_client_id
#   client_secret = var.azure_client_secret
#   resource      = "https://vault.hashicorp.com"
# }

# resource "vault_azure_auth_backend_role" "azurerole" {
#   backend                = vault_auth_backend.azure.path
#   role                   = "test-role"
#   bound_subscription_ids = [var.azure_subscription_id]
#   token_ttl              = 300
#   token_max_ttl          = 600
#   token_policies         = []
# }

# Azure Secrets Engine (Disabled)
# resource "vault_azure_secret_backend" "azure" {
#   subscription_id = var.azure_subscription_id
#   tenant_id       = var.azure_tanent_id
#   client_id       = var.azure_client_id
#   client_secret   = var.azure_client_secret
#   environment     = "AzurePublicCloud"
# }

# resource "vault_azure_secret_backend_role" "generated_role" {
#   backend                     = vault_azure_secret_backend.azure.path
#   role                        = "generated_role"
#   ttl                         = 300
#   max_ttl                     = 600

#   azure_roles {
#     role_name = "Reader"
#     scope =  "/subscriptions/${var.subscription_id}/resourceGroups/azure-vault-group"
#   }
# }

################################################################################
# APPROLE AUTHENTICATION
################################################################################

# AppRole Authentication
# Provides machine-to-machine authentication when native auth methods (AWS/GCP/Azure/K8s)
# are not available. AppRole roles are created per-application via the application module.
resource "vault_auth_backend" "approle" {
  type = "approle"
}

# Note: AppRole roles are created by the application module for each application
# and environment. Below is example code for manual AppRole role creation.

################################################################################
# PKI INFRASTRUCTURE
################################################################################

# PKI Root CA - Self-signed certificate authority
# This is the trust anchor for the PKI hierarchy. Kept offline in production.
resource "vault_mount" "pki_root" {
  path                      = "pki_root"
  type                      = "pki"
  default_lease_ttl_seconds = 3600 * 24 * 31 * 13     # ~13 months - default cert validity
  max_lease_ttl_seconds     = 3600 * 24 * 31 * 12 * 3 # 3 years - maximum cert validity
}

resource "vault_pki_secret_backend_root_cert" "self-signing-cert" {
  backend              = vault_mount.pki_root.path
  type                 = "internal"
  common_name          = "SelfSigned Root CA for ${var.environment}"
  ttl                  = 3600 * 24 * 31 * 12 * 10 # 10 years - root CA lifetime
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 2048
  exclude_cn_from_sans = true
  ou                   = "APJ SE"
  organization         = "Hashicorp Demo Org"
}

resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.pki_root.path
  issuing_certificates    = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/crl"]
}

# PKI Intermediate CA - Signs end-entity certificates
# This CA is used for day-to-day certificate issuance.
resource "vault_mount" "pki_intermediate" {
  depends_on                = [vault_pki_secret_backend_root_cert.self-signing-cert]
  path                      = "pki_intermediate"
  type                      = "pki"
  default_lease_ttl_seconds = 2678400  # 31 days - default cert validity
  max_lease_ttl_seconds     = 24819200 # ~13 months - max cert validity
}

resource "vault_pki_secret_backend_key" "private_key" {
  backend  = vault_mount.pki_intermediate.path
  type     = "internal"
  key_name = "private_key"
  key_type = "rsa"
  key_bits = "2048"
}


resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on  = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend     = vault_mount.pki_intermediate.path
  type        = "existing"
  key_ref     = vault_pki_secret_backend_key.private_key.key_id
  common_name = "Intermediate CA for ${var.environment}"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on           = [vault_pki_secret_backend_root_cert.self-signing-cert, vault_pki_secret_backend_root_cert.self-signing-cert]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  ttl                  = 3600 * 24 * 31 * 12 * 2 # 2 years - intermediate CA lifetime
  common_name          = "Intermediate CA for ${var.environment}"
  exclude_cn_from_sans = true
  ou                   = "APJ SE"
  organization         = "Hashicorp Demo Org"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  depends_on  = [vault_pki_secret_backend_config_urls.config_urls_int]
  backend     = vault_mount.pki_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_issuer" "default" {
  backend     = vault_pki_secret_backend_intermediate_set_signed.intermediate.backend
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name = "default-issuer"
}

# Alternative Intermediate CA Issuer - Redundancy/failover
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate-alt" {
  depends_on  = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend     = vault_mount.pki_intermediate.path
  type        = "existing"
  key_ref     = vault_pki_secret_backend_key.private_key.key_id
  common_name = "Intermediate CA for ${var.environment}"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate-alt" {
  depends_on           = [vault_pki_secret_backend_root_cert.self-signing-cert, vault_pki_secret_backend_root_cert.self-signing-cert]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate-alt.csr
  ttl                  = 3600 * 24 * 31 * 12 * 3 # 3 years - alt issuer lifetime
  common_name          = "alt issuer for Intermediate CA for ${var.environment}"
  exclude_cn_from_sans = true
  ou                   = "APJ SE"
  organization         = "Hashicorp Demo Org"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate-alt" {
  depends_on  = [vault_pki_secret_backend_config_urls.config_urls_int]
  backend     = vault_mount.pki_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate-alt.certificate
}

resource "vault_pki_secret_backend_issuer" "alt-issuer" {
  backend     = vault_pki_secret_backend_intermediate_set_signed.intermediate.backend
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate-alt.imported_issuers[0]
  issuer_name = "alt-issuer"
}


resource "vault_pki_secret_backend_config_urls" "config_urls_int" {
  backend                 = vault_mount.pki_intermediate.path
  issuing_certificates    = ["${var.vault_url}/v1/${vault_mount.pki_intermediate.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/v1/${vault_mount.pki_intermediate.path}/crl"]
}

################################################################################
# SECRETS ENGINES
################################################################################

# Transit Secrets Engine - Encryption as a Service (EaaS)
# Provides cryptographic operations without exposing keys.
resource "vault_mount" "encryption-as-a-service" {
  path                      = "EaaS"
  type                      = "transit"
  description               = "Encryption/Decryption as a Service for HashiCorp SE"
  default_lease_ttl_seconds = 3600  # 1 hour
  max_lease_ttl_seconds     = 86400 # 24 hours
}

resource "vault_transit_secret_backend_key" "hashi-encryption-key" {
  backend                = vault_mount.encryption-as-a-service.path
  name                   = "hashi-encryption-key"
  deletion_allowed       = true
  exportable             = false
  allow_plaintext_backup = true
}

# AWS Secrets Engine - Dynamic AWS credentials
resource "vault_aws_secret_backend" "aws" {
  description               = "AWS secrets engine for ${var.environment}"
  region                    = "ap-southeast-2"
  default_lease_ttl_seconds = 600       # 10 minutes
  max_lease_ttl_seconds     = 3600 * 48 # 48 hours (2 days)
}


resource "vault_aws_secret_backend_role" "iam_manager" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "iam_manager"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "s3_manager" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "s3_manager"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "cicdpipeline" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "cicdpipeline"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "cicdpipelinests" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "cicdpipelinests"
  credential_type = "federation_token"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOT
}

# SSH Secrets Engine - Signed SSH certificates
resource "tls_private_key" "ssh-ca-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "vault_mount" "ssh-client-signer" {
  path = "ssh-client-signer"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "ssh-ca" {
  backend              = vault_mount.ssh-client-signer.path
  private_key          = tls_private_key.ssh-ca-key.private_key_pem
  public_key           = tls_private_key.ssh-ca-key.public_key_openssh
  generate_signing_key = false
}

resource "vault_ssh_secret_backend_role" "ubuntu" {
  backend            = vault_mount.ssh-client-signer.path
  name               = "ubuntu"
  key_type           = "ca"
  default_user       = "ubuntu"
  allowed_extensions = "permit-pty,permit-port-forwarding"
  default_extensions = {
    permit-pty             = true
    permit-port-forwarding = true
  }
  allow_user_certificates = true
  cidr_list               = ""
  ttl                     = 12 * 3600 # 12 hours - signed SSH certificate validity
}

################################################################################
# UI CONFIGURATION
################################################################################

resource "vault_config_ui_custom_message" "maintenance" {
  title          = "HashiCorp Employees, welcome!"
  message_base64 = base64encode("\nHashiCorp Employees can login to Vault using their github personal token.\n\nThe configuration of this cluster is managed using terraform code. Please do not make any manual changes to the configuration.\n\nFor any changes, please raise a PR in the repository.")
  type           = "modal"
  link {
    href  = "https://github.com/ausmartway/vault-config-as-code"
    title = "vault-config-as-code"
  }

  authenticated = false
  start_time    = "2024-01-01T00:00:00Z"
}

# Audit Device (Disabled)
# resource "vault_audit" "auditlog" {
#   type = "file"
#   options = {
#     file_path = "/tmp/vault_audit.log"
#   }
# }
