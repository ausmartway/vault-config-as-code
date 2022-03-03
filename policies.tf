resource "vault_policy" "test-role-policy" {
  name = "test-role-policy"

  policy = <<EOT
path "kv/secrets" {
  capabilities = ["read"]
}
EOT
}