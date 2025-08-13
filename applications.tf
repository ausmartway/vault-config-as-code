module "applications" {
  source         = "ausmartway/kv-for-application/vault"
  version        = "0.4.1"
  for_each       = local.applications_map
  appname        = each.value.appid
  enable_approle = each.value.enable_approle
  enviroments    = each.value.enviroments
  depends_on = [
    vault_auth_backend.approle
  ]
}
