variable "vault_url" {
  type        = string
  description = "The URL to vault, no default value provided"
}

variable "environment" {
  type        = string
  description = "environment, no default value provided"
}

################################################################################
# DISABLED CONFIGURATIONS
################################################################################

# Azure Authentication (Disabled)
# Azure auth backend configuration is managed separately.
# Uncomment and configure when Azure integration is required.
# Note: Fix "tanent" typo to "tenant" when enabling.

# variable "azure_tenant_id" {
#   type        = string
#   description = "Azure tenant id"
# }

# variable "azure_client_id" {
#   type        = string
#   description = "Azure client id"
# }

# variable "azure_client_secret" {
#   type        = string
#   description = "Azure client secret"
# }

# variable "azure_subscription_id" {
#   type        = string
#   description = "Azure subscription id"
# }

variable "tfc_vault_dynamic_credentials" {
  description = "Object containing Vault dynamic credentials configuration"
  type = object({
    default = object({
      token_filename = string
      address        = string
      namespace      = string
      ca_cert_file   = string
    })
    aliases = map(object({
      token_filename = string
      address        = string
      namespace      = string
      ca_cert_file   = string
    }))
  })
}
