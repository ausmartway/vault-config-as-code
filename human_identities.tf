resource "vault_identity_oidc_key" "human" {
  name      = "human"
  algorithm = "RS256"
}

resource "vault_identity_oidc_role" "human" {
  name = "human"
  key  = vault_identity_oidc_key.human.name
}

resource "vault_identity_entity" "yulei" {
  name     = "yulei"
  policies = ["superuser", "human-identity-token-policies"]
  metadata = {
    role = "Sales"
    team = "SalesEngineer"
  }
}

resource "vault_policy" "human-identity-token-policies" {
  name   = "yulei-identity-token-policies"
  policy = <<EOF
 path "identity/oidc/token/human" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}

resource "vault_identity_entity_alias" "yulei-github" {
  name           = "ausmartway"
  mount_accessor = vault_github_auth_backend.hashicorp.accessor
  canonical_id   = vault_identity_entity.yulei.id
}

resource "vault_identity_entity_alias" "yulei-pki" {
  name           = "yulei"
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.yulei.id
}

