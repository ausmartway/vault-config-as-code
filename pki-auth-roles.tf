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

resource "vault_policy" "trusted-orchestrator" {
  name   = "trusted-orchestrator"
  policy = <<EOF
 path "pki_intermediate/issue/machine-id" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}

resource "vault_token_auth_backend_role" "trusted-orchestrator" {
  role_name              = "trusted-orchestrator"
  allowed_policies       = ["trusted-orchestrator"]
  orphan                 = true
  token_period           = "86400"
  renewable              = true
  token_explicit_max_ttl = "115200"
  path_suffix            = "trusted-orchestrator"
}

resource "vault_token" "trusted-orchestrator" {
  role_name    = "trusted-orchestrator"
  display_name = "trusted-orchestrator"
  policies     = [vault_policy.trusted-orchestrator.name, "default"]

  renewable = true
  ttl       = "2184h" #3 Months

  renew_min_lease = 43200
  renew_increment = 86400
}

output "trusted-orchestrator" {
  value = vault_token.trusted-orchestrator.token
  sensitive=false
}

resource "vault_egp_policy" "only-allow-machines-to-request-their-own-id" {
  name              = "only-allow-machines-to-request-their-own-id"
  paths             = ["pki_intermediate/issue/machine-id"]
  enforcement_level = "hard-mandatory"

  policy = <<EOT

trace = true
entity_is_trusted_orchestrator = rule {
    token.display_name is "token-trusted-orchestrator"
}

entity_name_match_request = rule {
  identity.entity.aliases[0].name is request.data.common_name
}

if entity_is_trusted_orchestrator {
  print("Sentinel debug: token.display_name:",token.display_name)
} else {
  print("Your machine-id is:",identity.entity.aliases[0].name)
}
if trace {
  if request is not undefined {
    print("trace:Request:",request)
  }
  if token is not undefined {
    print("trace:Token:",token)
  }
  if identity.entity is not undefined {
    print("trace:identity.entity:",identity.entity)
  }
}
print("You are not elidgiable to request machine-id:",request.data.common_name)

main = rule {
  //Sentinel for Vault will only print when main rule is false, if we want trace info, we shoud always fail when trace=true
    (entity_is_trusted_orchestrator or entity_name_match_request) and not trace
}

EOT
}