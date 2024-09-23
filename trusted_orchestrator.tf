resource "vault_policy" "trusted-orchestrator" {
  name   = "trusted-orchestrator"
  policy = <<EOF
 path "pki_intermediate/issue/machine-id" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}

resource "vault_token_auth_backend_role" "trusted-orchestrator" {
  role_name              = "trusted-orchestrator"
  allowed_policies       = ["trusted-orchestrator"]
  orphan                 = true
  token_period           = "86400"
  renewable              = true
  token_explicit_max_ttl = "115200"
  path_suffix            = "trusted-orchestrator"
}

resource "vault_token" "trusted-orchestrator" {
  role_name         = "trusted-orchestrator"
  display_name      = "trusted-orchestrator"
  policies          = [vault_policy.trusted-orchestrator.name]
  no_parent         = true
  renewable         = true
  ttl               = "365d" # 1 year Months
  no_default_policy = false
  renew_min_lease   = 43200
  renew_increment   = 86400
  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [time_static.rotate]
  }
}

output "trusted-orchestrator" {
  value     = vault_token.trusted-orchestrator.client_token
  sensitive = true
}
