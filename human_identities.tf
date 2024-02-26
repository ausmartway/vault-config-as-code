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
  name   = "human-identity-token-policies"
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

#create a signing key for the human identity
resource "vault_identity_oidc_key" "human_identity" {
  name      = "human_identity"
  algorithm = "RS256"
}

#create human role so that it can be used to generate tokens. the token format is defined in the role 
#example of the token format is azp = "spiffe://TRUSTDOMAIN/ENVIROMENT/BUSINESS_UNIT/ENTITY_NAME"

resource "vault_identity_oidc_role" "human_identity" {
  name      = "human_identity"
  client_id = "spiffe://vault"
  key       = vault_identity_oidc_key.human_identity.name
  template  = <<EOF
{
  "azp": "spiffe://vault/{{identity.entity.metadata.role}}/{{identity.entity.metadata.team}}/{{identity.entity.name}}"
}
EOF
}

#allow the human identity to use the role/key to generate identity tokens
resource "vault_identity_oidc_key_allowed_client_id" "hunam_identity" {
  key_name          = vault_identity_oidc_key.human_identity.name
  allowed_client_id = vault_identity_oidc_role.human_identity.client_id
}