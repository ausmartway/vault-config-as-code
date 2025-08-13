resource "vault_identity_group" "identity_group" {
  for_each                   = local.identity_groups_map
  name                       = each.key
  type                       = "internal"
  external_member_entity_ids = true # This is set to true bso member_entity_ids returned will not be considered as changes to this resource - they are mananged externally in a decoupled way
  external_member_group_ids  = true # This is set to true bso member_group_ids returned will not be considered as changes to this resource - they are mananged externally in a decoupled way
  policies                   = [for i in each.value.identity_group_policies : i]
}

resource "vault_identity_group_member_entity_ids" "human_group" {
  for_each          = local.identity_groups_map
  group_id          = vault_identity_group.identity_group[each.key].id
  member_entity_ids = [for i in each.value.human_identities : vault_identity_entity.human[i].id]
  exclusive         = false
}

resource "vault_identity_group_member_entity_ids" "application_group" {
  for_each          = local.identity_groups_map
  group_id          = vault_identity_group.identity_group[each.key].id
  member_entity_ids = [for i in each.value.application_identities : vault_identity_entity.application[i].id]
  exclusive         = false
}

resource "vault_identity_group_member_group_ids" "group_group" {
  for_each         = local.identity_groups_map
  group_id         = vault_identity_group.identity_group[each.key].id
  member_group_ids = [for i in each.value.sub_groups : vault_identity_group.identity_group[i].id]
  exclusive        = false
}

