# Vault Provider Configuration
#
# Authentication is configured via environment variables:
#   VAULT_ADDR  - Vault server URL (e.g., http://localhost:8200)
#   VAULT_TOKEN - Authentication token
#
# For local development:
#   export VAULT_ADDR=http://localhost:8200
#   export VAULT_TOKEN=dev-root-token
#
# For production, use a more secure authentication method such as:
#   - AppRole with wrapped secret ID
#   - Cloud provider workload identity (AWS IAM, GCP, Azure)
#   - Terraform Cloud dynamic credentials
provider "vault" {
  // skip_child_token must be explicitly set to true as HCP Terraform manages the token lifecycle
  skip_child_token = true
  address          = var.tfc_vault_dynamic_credentials.default.address
  namespace        = var.tfc_vault_dynamic_credentials.default.namespace

  auth_login_token_file {
    filename = var.tfc_vault_dynamic_credentials.default.token_filename
  }
}
