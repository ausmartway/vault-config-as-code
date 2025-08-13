resource "vault_auth_backend" "cert" {
  type = "cert"
  path = "cert"
  tune {
    listing_visibility = "unauth"
  }
}

resource "vault_cert_auth_backend_role" "authrole" {
  for_each       = local.pki_auth_roles_map
  certificate    = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
  backend        = each.value.backend
  name           = each.value.name
  token_ttl      = each.value.ttl
  token_max_ttl  = each.value.maxttl
  token_policies = each.value.policies
  allowed_names  = each.value.allowed_machine_ids
}

resource "vault_policy" "pki-self-renewal" {
  name   = "pki-self-renewal"
  policy = <<EOF
 path "pki_intermediate/issue/machine-id" {
   capabilities = ["update","list"]
 }
 EOF
}

resource "vault_policy" "server-pki" {
  name   = "server-pki"
  policy = <<EOF
 path "pki_intermediate/issue/server_pki" {
   capabilities = ["update","list"]
 }
 EOF
}

resource "vault_policy" "client-pki" {
  name   = "client-pki"
  policy = <<EOF
 path "pki_intermediate/issue/client_pki" {
   capabilities = ["update","list"]
 }
 EOF
}