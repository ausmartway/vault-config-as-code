
locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputhumanvars = [for f in fileset(path.module, "identities/{human_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files.Those yaml files need to have the same structure otherwise toset() will fail.
  inputhumanmap = { for human in toset(local.inputhumanvars) : human.name => human }

  # Filter out any humans that do not have a github id
  human_with_github = { for k, v in local.inputhumanmap : k => v if v.github != tostring(null) }
  # Filter out any humans that do not have a pki
  human_with_pki = { for k, v in local.inputhumanmap : k => v if v.pki != tostring(null) }
}

resource "vault_identity_entity" "human" {
  for_each = local.inputhumanmap
  name     = each.key
  policies = concat([for i in each.value.identity_policies : i], ["human-identity-token-policies"])
  metadata = {
    role      = each.value.role
    team      = each.value.team
    spiffe_id = "spiffe://vault/human/${each.value.role}/${each.value.team}/${each.value.name}"
  }
}

# for each human with a github create an alias that points back to the human entity
resource "vault_identity_entity_alias" "github" {
  for_each       = local.human_with_github
  mount_accessor = vault_github_auth_backend.hashicorp.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.github
}

# for each human with a pki create an alias that points back to the human entity
resource "vault_identity_entity_alias" "pki" {
  for_each       = local.human_with_pki
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.pki
}

locals {
  # Take a direcotry of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputappidvars = [for f in fileset(path.module, "identities/{application_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from YAML files. Those yaml files need to have the same structure otherwise toset() will fail.
  inputappidmap = { for app in toset(local.inputappidvars) : app.name => app }

  # Filter out any applications that do not have a github_repo 
  app_with_github_repo = { for k, v in local.inputappidmap : k => v if v.github_repo != tostring(null) }
  # Filter out any applications that do not have a pki 
  app_with_pki = { for k, v in local.inputappidmap : k => v if v.pki != tostring(null) }
}

resource "vault_identity_entity" "application" {
  for_each = local.inputappidmap
  name     = each.key
  policies = [for i in each.value.identity_policies : i]
  metadata = {
    enviroment    = each.value.enviroment
    business_unit = each.value.business_unit
    spiffe_id     = "spiffe://vault/application/${each.value.enviroment}/${each.value.business_unit}/${each.value.name}"
  }
}

# for each app with a pki create an alias that points back to the application entity
resource "vault_identity_entity_alias" "app_pki" {
  for_each       = local.app_with_pki
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.application[each.key].id
  name           = each.value.pki
}

# for each app with a github_repo create an alias that points back to the application entity
resource "vault_identity_entity_alias" "app_github_repo" {
  for_each       = local.app_with_github_repo
  mount_accessor = vault_jwt_auth_backend.github_repo_jwt.accessor
  canonical_id   = vault_identity_entity.application[each.key].id
  name           = each.value.github_repo
}