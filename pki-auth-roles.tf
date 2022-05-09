locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputpki-auth-role-vars = [for f in fileset(path.module, "pki-auth-roles/{pki-auth-role}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files
  inputpki-auth-role-map = { for pki-auth-role in toset(local.inputpki-auth-role-vars) : pki-auth-role.name => pki-auth-role }
}

resource "vault_pki_secret_backend_role" "role" {
  for_each        = local.inputpki-auth-role-map
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
  allow_any_name     = false
  allow_ip_sans      = false
  require_cn         = true
  depends_on = [
    vault_mount.pki_intermediate
  ]
}

resource "vault_cert_auth_backend_role" "authrole" {
  for_each       = local.inputpki-auth-role-map
  backend        = each.value.backend
  name           = each.value.name
  ttl            = each.value.ttl
  max_ttl        = each.value.maxttl
  token_policies = [each.value.policies]
  allowed_names  = [each.value.allowed_names]
}
