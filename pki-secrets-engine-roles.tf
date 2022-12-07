locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputpkirolevars = [for f in fileset(path.module, "pki-secrets-roles/{pkirole}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files
  inputpkirolemap = { for pkirole in toset(local.inputpkirolevars) : pkirole.name => pkirole }
}

resource "vault_pki_secret_backend_role" "role" {
  for_each        = local.inputpkirolemap
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

resource "vault_pki_secret_backend_role" "server_pki" {
name = server_pki
backend= pki_intermediate
ttl = 3 * 31 * 24 * 3600 //3 month
maxttl = 12 * 31 * 24 * 3600 //3 month
  allow_bare_domains = false
  allow_subdomains   = true
  allow_any_name     = false
  allow_ip_sans      = false
  require_cn         = true
server_flag = true
client_flag = false
allowed_domains = ["customer.demo"]
  depends_on = [
    vault_mount.pki_intermediate
  ]
}

resource "vault_pki_secret_backend_role" "client_pki" {
  name = client_pki
backend= pki_intermediate
ttl = 3 * 31 * 24 * 3600 //3 month
maxttl = 12 * 31 * 24 * 3600 //3 month
  allow_bare_domains = false
  allow_subdomains   = true
  allow_any_name     = false
  allow_ip_sans      = false
  require_cn         = true
server_flag = false
client_flag = true
allowed_domains = ["customer.demo"]
  depends_on = [
    vault_mount.pki_intermediate
  ]
  
}