resource "vault_pki_secret_backend_role" "role" {
  for_each        = local.pki_roles_map
  backend         = each.value.backend
  name            = each.value.name
  ttl             = each.value.ttl
  max_ttl         = each.value.maxttl
  allow_localhost = false
  allowed_domains = each.value.allowed_domains
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment"
  ]
  allow_bare_domains = false
  allow_subdomains   = true
  allow_any_name     = each.value.allow_any_name
  allow_ip_sans      = false
  require_cn         = true
  issuer_ref         = vault_pki_secret_backend_issuer.default.issuer_ref

  # the type of below fields should be just string, instead of list(string), I will fix it later
  ou             = [each.value.ou]
  organization   = [each.value.organization]
  country        = [each.value.country]
  locality       = [each.value.locality]
  province       = [each.value.province]
  street_address = [each.value.street_address]
  postal_code    = [each.value.postal_code]

  depends_on = [
    vault_mount.pki_intermediate
  ]
}