locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputidentitygroupvars = [for f in fileset(path.module, "identity_groups/{identity_group_}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  inputidentitygroupmap = { for identity_group in toset(local.inputidentitygroupvars) : identity_group.name => identity_group }
}

resource "vault_identity_group" "identity_group" {
  for_each                   = local.inputidentitygroupmap
  name                       = each.key
  type                       = "internal"
  external_member_entity_ids = true
}

resource "vault_identity_group_member_entity_ids" "human_group" {
  for_each          = local.inputidentitygroupmap
  group_id          = vault_identity_group.identity_group[each.key].id
  member_entity_ids = [for i in each.value.human_identities : vault_identity_entity.human[i].id]
  exclusive         = false
}

resource "vault_identity_group_member_entity_ids" "application_group" {
  for_each          = local.inputidentitygroupmap
  group_id          = vault_identity_group.identity_group[each.key].id
  member_entity_ids = [for i in each.value.application_identities : vault_identity_entity.application[i].id]
  exclusive         = false
}

resource "vault_identity_group_member_group_ids" "group_group" {
  for_each         = local.inputidentitygroupmap
  group_id         = vault_identity_group.identity_group[each.key].id
  member_group_ids = [for i in each.value.sub_groups : vault_identity_group.identity_group[i].id]
  exclusive        = false
}

