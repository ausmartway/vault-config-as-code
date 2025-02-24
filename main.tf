//github auth backend, as long as you belong to the hashicorp orgnisation, you will be able to login to Vault and get super user previlige using your personal github token.
resource "vault_github_auth_backend" "hashicorp" {
  organization   = "hashicorp"
  token_policies = [""]
}

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


### Super user policy ###
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


// github repository jwt auth method
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
  bound_audiences = ["eXVsZWkncyBWYXVsdAo="] ##Base64 encoded value of "Yulie's Vault"
  user_claim      = "repository"
  role_type       = "jwt"
}

// Terraform Cloud auth method
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
  bound_audiences   = ["eXVsZWkncyBWYXVsdAo="]   ##Base64 encoded value of "Yulie's Vault"
  user_claim        = "terraform_full_workspace" ##This is the FULL name of the workspace in Terraform Cloud, in the format of "organization:organization_name:project:project_name:workspace:workspace_name", 
  bound_claims_type = "glob"
  bound_claims      = { "terraform_organization_name" = "yulei" } ##This is the name of the organization in Terraform Cloud
  role_type         = "jwt"
}


//aws auth method

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
# //azure auth method
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

# //azure secret engine

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


//Approle auth method

resource "vault_auth_backend" "approle" {
  type = "approle"
}

# Approle should only be used when there is no better/native authentication, eg, aws/gcp/azure/k8s/ldap.
# The approle roles in this repository will be created by the application module, for each application and enviroments. 
# Below codes are just examples if you want to create approle roles outside of the application module.

// //pki root CA secret engine
resource "vault_mount" "pki_root" {
  path                      = "pki_root"
  type                      = "pki"
  default_lease_ttl_seconds = 3600 * 24 * 31 * 13     //13 Months
  max_lease_ttl_seconds     = 3600 * 24 * 31 * 12 * 3 //3 Years
}
resource "vault_pki_secret_backend_root_cert" "self-signing-cert" {
  backend              = vault_mount.pki_root.path
  type                 = "internal"
  common_name          = "SelfSigned Root CA for ${var.enviroment}"
  ttl                  = 3600 * 24 * 31 * 12 * 10 //10 Years
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "APJ SE"
  organization         = "Hashicorp Demo Org"
}
resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.pki_root.path
  issuing_certificates    = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/crl"]
}
//pki intermediate CA secret engine
resource "vault_mount" "pki_intermediate" {
  depends_on                = [vault_pki_secret_backend_root_cert.self-signing-cert]
  path                      = "pki_intermediate"
  type                      = "pki"
  default_lease_ttl_seconds = 2678400  //Default expiry of the certificates signed by this CA - 31 days
  max_lease_ttl_seconds     = 24819200 //Max expiry of the certificates signed by this CA - 13 Months
}
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on  = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend     = vault_mount.pki_intermediate.path
  type        = "internal"
  common_name = "Intermediate CA for ${var.enviroment}"
}
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on           = [vault_pki_secret_backend_root_cert.self-signing-cert, vault_pki_secret_backend_root_cert.self-signing-cert]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  ttl                  = 3600 * 24 * 31 * 12 * 2 //2 Years
  common_name          = "Intermediate CA for ${var.enviroment}"
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

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate-alt" {
  depends_on  = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend     = vault_mount.pki_intermediate.path
  type        = "internal"
  common_name = "Intermediate CA for ${var.enviroment}"
}
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate-alt" {
  depends_on           = [vault_pki_secret_backend_root_cert.self-signing-cert, vault_pki_secret_backend_root_cert.self-signing-cert]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate-alt.csr
  ttl                  = 3600 * 24 * 31 * 12 * 3 //3 Years
  common_name          = "alt issuer for Intermediate CA for ${var.enviroment}"
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

//transit secret engine
resource "vault_mount" "encryption-as-a-service" {
  path                      = "EaaS"
  type                      = "transit"
  description               = "Encryption/Decryption as a Service for HashiCorp SE"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "hashi-encryption-key" {
  backend                = vault_mount.encryption-as-a-service.path
  name                   = "hashi-encryption-key"
  deletion_allowed       = true
  exportable             = false
  allow_plaintext_backup = true
}

//aws secrets engine
resource "vault_aws_secret_backend" "aws" {
  description               = "AWS secrets engine for ${var.enviroment}"
  region                    = "ap-southeast-2"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 3600 * 48 // two days
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

# ssh secret engine
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
  ttl                     = 12 * 3600 #sighed ssh certificate will be valid for 12 hours
}

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

# //Audit device
# resource "vault_audit" "auditlog" {
#   type = "file"
#   options = {
#     file_path = "/tmp/vault_audit.log"
#   }
# }