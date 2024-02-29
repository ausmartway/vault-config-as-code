
locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputhumanvars = [for f in fileset(path.module, "identities/{human_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files
  inputhumanmap = { for human in toset(local.inputhumanvars) : human.name => human }
}

resource "vault_identity_entity" "human" {
  for_each = local.inputhumanmap
  name     = each.key
  policies = ["human-identity-token-policies"]
  metadata = {
    role      = each.value.role
    team      = each.value.team
    spiffe_id = "spiffe://vault/human/${each.value.role}/${each.value.team}/${each.value.name}"
  }
}

resource "vault_identity_entity_alias" "github" {
  for_each       = local.inputhumanmap
  mount_accessor = vault_github_auth_backend.hashicorp.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.github
}

resource "vault_identity_entity_alias" "pki" {
  for_each       = local.inputhumanmap
  mount_accessor = vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.human[each.key].id
  name           = each.value.pki
}

locals {
  # Take a direcotry of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputappidvars = [for f in fileset(path.module, "identities/{application_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from YAML files
  inputappidmap = { for app in toset(local.inputappidvars) : app.name => app }
}

resource "vault_identity_entity" "application" {
  for_each = local.inputappidmap
  name     = each.key
  policies = ["application-identity-token-policies"]
  metadata = {
    enviroment    = each.value.enviroment
    business_unit = each.value.business_unit
    spiffe_id     = "spiffe://vault/application/${each.value.enviroment}/${each.value.business_unit}/${each.value.name}"
  }
}