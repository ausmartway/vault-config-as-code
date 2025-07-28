
locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputhumanvars = [for f in fileset(path.module, "identities/{human_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files.Those yaml files need to have the same structure otherwise toset() will fail.
  inputhumanmap = { for human in toset(local.inputhumanvars) : human.identity.name => human }

  # Filter out any humans that do not have a github id
  human_with_github = { for k, v in local.inputhumanmap : k => v if v.identity.github != tostring(null) }
  # Filter out any humans that do not have a pki
  human_with_pki = { for k, v in local.inputhumanmap : k => v if v.authentication.pki != tostring(null) }
}

resource "vault_identity_entity" "human" {
  for_each = local.inputhumanmap
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
  name           = each.value.identity.github
}

# for each human with a pki create an alias that points back to the human entity
resource "vault_identity_entity_alias" "pki" {
  for_each       = local.human_with_pki
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.authentication.pki
}

locals {
  # Take a direcotry of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputappidvars = [for f in fileset(path.module, "identities/{application_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from YAML files. Those yaml files need to have the same structure otherwise toset() will fail.
  inputappidmap = { for app in toset(local.inputappidvars) : app.identity.name => app }

  # Filter out any applications that do not have a github_repo 
  app_with_github_repo = { for k, v in local.inputappidmap : k => v if v.authentication.github_repo != tostring(null) && v.authentication.github_repo != "" }
  # Filter out any applications that do not have a pki 
  app_with_pki           = { for k, v in local.inputappidmap : k => v if v.authentication.pki != tostring(null) && v.authentication.pki != "" }
  app_with_tfc_workspace = { for k, v in local.inputappidmap : k => v if v.authentication.tfc_workspace != tostring(null) && v.authentication.tfc_workspace != "" }
}

resource "vault_identity_entity" "application" {
  for_each = local.inputappidmap
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