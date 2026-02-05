################################################################################
# TRUSTED ORCHESTRATOR
################################################################################

# Trusted Orchestrator Policy
# Grants elevated privileges to infrastructure automation tools (e.g., Terraform)
# to provision machine identity certificates on behalf of other machines.
resource "vault_policy" "trusted-orchestrator" {
  name   = "trusted-orchestrator"
  policy = <<EOF
 path "pki_intermediate/issue/machine-id" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}

# Token Auth Backend Role for Trusted Orchestrator
# Defines the token properties for orchestrator authentication
resource "vault_token_auth_backend_role" "trusted-orchestrator" {
  role_name              = "trusted-orchestrator"
  allowed_policies       = ["trusted-orchestrator"]
  orphan                 = true
  token_period           = "86400" # 1 day - token refresh interval
  renewable              = true
  token_explicit_max_ttl = "115200" # 32 hours - hard expiration limit
  path_suffix            = "trusted-orchestrator"
}

# Trusted Orchestrator Token
# Long-lived token for infrastructure automation with auto-rotation
resource "vault_token" "trusted-orchestrator" {
  role_name         = "trusted-orchestrator"
  display_name      = "trusted-orchestrator"
  policies          = [vault_policy.trusted-orchestrator.name]
  no_parent         = true
  renewable         = true
  ttl               = "365d" # 1 year - token lifetime
  no_default_policy = false
  renew_min_lease   = 43200 # 12 hours - minimum time before renewal allowed
  renew_increment   = 86400 # 1 day - each renewal extends by this amount
  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [time_static.rotate]
  }
}

output "trusted-orchestrator" {
  value     = vault_token.trusted-orchestrator.client_token
  sensitive = true
}
