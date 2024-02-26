resource "vault_identity_entity" "corebanking" {
  name     = "corebanking"
  policies = ["superuser", "application-identity-token-policies"]
  metadata = {
    enviroment    = "production"
    business_unit = "retail"
  }
}

resource "vault_policy" "application-identity-token-policies" {
  name   = "application-identity-token-policies"
  policy = <<EOF
 path "identity/oidc/token/application" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}

resource "vault_identity_entity_alias" "corebanking-aws-ec2" {
  name           = "corebanking-aws-ec2"
  mount_accessor = vault_auth_backend.aws.accessor
  canonical_id   = vault_identity_entity.corebanking.id
}

#create a signing key for the application identity
resource "vault_identity_oidc_key" "application_identity" {
  name      = "application_identity"
  algorithm = "RS256"
}

#create application role so that it can be used to generate tokens. the token format is defined in the role 
#example of the token format is azp = "spiffe://TRUSTDOMAIN/ENVIROMENT/BUSINESS_UNIT/ENTITY_NAME"

resource "vault_identity_oidc_role" "application_identity" {
  name      = "application_identity"
  client_id = "spiffe://vault"
  key       = vault_identity_oidc_key.application_identity.name
  template  = <<EOF
{
    "azp": "spiffe://vault/"
}
  EOF
}

#allow the application identity to use the role/key to generate identity tokens
resource "vault_identity_oidc_key_allowed_client_id" "application_identity" {
  key_name          = vault_identity_oidc_key.application_identity.name
  allowed_client_id = vault_identity_oidc_role.application_identity.client_id
}

