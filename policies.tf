resource "vault_policy" "test-role-policy" {
  name = "test-role-policy"

  policy = <<EOT
path "kv/*" {
  capabilities = ["read","list"]
}

path "auth/token/*" {
  capabilities = ["create", "update"]
}

EOT
}

resource "vault_policy" "cicdpipeline" {
  name = "cicdpipeline"

  policy = <<EOT
path "aws/creds/cicdpipeline" {
  capabilities = ["read","list"]
}

path "auth/token/*" {
  capabilities = ["create", "update"]
}

EOT
}