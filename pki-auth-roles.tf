locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputpki-auth-role-vars = [for f in fileset(path.module, "pki-auth-roles/{pki-auth-role}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files
  inputpki-auth-role-map = { for pki-auth-role in toset(local.inputpki-auth-role-vars) : pki-auth-role.name => pki-auth-role }
}

resource "vault_cert_auth_backend_role" "authrole" {
  for_each       = local.inputpki-auth-role-map
  certificate    = vault_pki_secret_backend_root_sign_intermediate.root.certificate
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
  name   = "server-pki"
  policy = <<EOF
 path "pki_intermediate/issue/client_pki" {
   capabilities = ["update","list"]
 }
 EOF
}
