

#create a signing key for the application identity
resource "vault_identity_oidc_key" "application_identity" {
  name      = "application_identity"
  algorithm = "RS256"
}

#create application role so that it can be used to generate tokens. the token format is defined in the role 
#example of the token format is azp = "spiffe://TRUSTDOMAIN/ENVIROMENT/BUSINESS_UNIT/ENTITY_NAME"

resource "vault_identity_oidc_role" "application_identity" {
  name     = "application_identity"
  template = <<EOT
{
  "azp": {{identity.entity.metadata.spiffe_id}},
  "nbf": {{time.now}}
}
EOT

  client_id = "spiffe://glueegateway"
  key       = vault_identity_oidc_key.application_identity.name
  ttl       = 30 * 60 // 30 minutes for application identity token
}

#allow the application identity to use the role/key to generate identity tokens
resource "vault_identity_oidc_key_allowed_client_id" "application_identity" {
  key_name          = vault_identity_oidc_key.application_identity.name
  allowed_client_id = vault_identity_oidc_role.application_identity.client_id
}

#create a policy that allows the applications to generate identity tokens
resource "vault_policy" "application-identity-token-policies" {
  name   = "application-identity-token-policies"
  policy = <<EOF
 path "identity/oidc/token/application_identity" {
   capabilities = ["read"]
 }
 EOF
}

#create a signing key for the human identity
resource "vault_identity_oidc_key" "human_identity" {
  name      = "human_identity"
  algorithm = "RS256"
}

#cretae a role for the human identity so that it can be used to generate tokens. the token format is defined in the role
resource "vault_identity_oidc_role" "human_identity" {
  name      = "human_identity"
  template  = <<EOT
{
  "azp": {{identity.entity.metadata.spiffe_id}},
  "nbf": {{time.now}}
}
EOT
  client_id = "spiffe://glueegateway"
  key       = vault_identity_oidc_key.human_identity.name
  ttl       = 8 * 60 * 60 // 8 hours for human identity token
}

#allow the human identity to use the role/key to generate identity tokens
resource "vault_identity_oidc_key_allowed_client_id" "human_identity" {
  key_name          = vault_identity_oidc_key.human_identity.name
  allowed_client_id = vault_identity_oidc_role.human_identity.client_id
}

#create a policy that allows the humans to generate identity tokens
resource "vault_policy" "human-identity-token-policies" {
  name   = "human-identity-token-policies"
  policy = <<EOF
 path "identity/oidc/token/human_identity" {
   capabilities = ["read"]
 }
 EOF
}
