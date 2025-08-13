
module "vault_namespace" {
  source   = "ausmartway/namespace/vault"
  version  = "0.0.3"
  for_each = local.namespaces_map
  name     = each.value.name
} 