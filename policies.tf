resource "vault_policy" "test-role-policy" {
  name = "test-role-policy"

  policy = <<EOT
path "kv/secrets" {
  capabilities = ["read","list"]
}

path "auth/token/*" {
  capabilities = ["create", "update"]
}

EOT
}