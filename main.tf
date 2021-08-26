//github auth backend, as long as you belong to the hashicorp orgnisation, you will be able to login to Vault and get super user previlige using your personal github token.
resource "vault_github_auth_backend" "hashicorp" {
  organization   = "hashicorp"
  token_policies = ["super-user"]
}

resource "vault_policy" "super-user" {
  name   = "super-user"
  policy = <<EOF
 path "*" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}