
resource "vault_identity_entity" "human" {
  for_each = local.human_identities_map
  name     = each.key
  policies = concat([for i in each.value.policies.identity_policies : i], ["human-identity-token-policies"])
  metadata = {
    role      = each.value.identity.role
    team      = each.value.identity.team
    spiffe_id = "spiffe://vault/human/${each.value.identity.role}/${each.value.identity.team}/${each.value.identity.name}"
  }
}

# for each human with a github create an alias that points back to the human entity
resource "vault_identity_entity_alias" "github" {
  for_each       = local.human_with_github
  mount_accessor = vault_github_auth_backend.hashicorp.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.authentication.github
}

# for each human with a pki create an alias that points back to the human entity
resource "vault_identity_entity_alias" "pki" {
  for_each       = local.human_with_pki
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.authentication.pki
}

resource "vault_identity_entity" "application" {
  for_each = local.application_identities_map
  name     = each.key
  policies = [for i in each.value.policies.identity_policies : i]
  metadata = {
    environment   = each.value.identity.environment
    business_unit = each.value.identity.business_unit
    spiffe_id     = "spiffe://vault/application/${each.value.identity.environment}/${each.value.identity.business_unit}/${each.value.identity.name}"
  }
}

# for each app with a pki create an alias that points back to the application entity
resource "vault_identity_entity_alias" "app_pki" {
  for_each       = local.app_with_pki
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.application[each.key].id
  name           = each.value.authentication.pki
}

# for each app with a github_repo create an alias that points back to the application entity
resource "vault_identity_entity_alias" "app_github_repo" {
  for_each       = local.app_with_github_repo
  mount_accessor = vault_jwt_auth_backend.github_repo_jwt.accessor
  canonical_id   = vault_identity_entity.application[each.key].id
  name           = each.value.authentication.github_repo
}

# for each app with a tfc_workspace create an alias that points back to the application entity
resource "vault_identity_entity_alias" "app_tfc_workspace" {
  for_each       = local.app_with_tfc_workspace
  mount_accessor = vault_jwt_auth_backend.terraform_cloud.accessor
  canonical_id   = vault_identity_entity.application[each.key].id
  name           = each.value.authentication.tfc_workspace
}