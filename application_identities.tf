resource vault_identity_entity "corebanking" {
  name     = "corebanking"
  policies = ["superuser", "human-identity-token-policies"]
  metadata = {
    enviroment = "production"
    business_unit = "retail"
  }
}

resource "vault_policy" "application-identity-token-policies" {
  name   = "yulei-identity-token-policies"
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

resource "vault_identity_oidc_key" "application_identity" {
  name      = "application_identity"
  algorithm = "RS256"
}

resource "vault_identity_oidc_role" "application_identity" {
  name = "application_identity"
  key  = vault_identity_oidc_key.application_identity.name
}


