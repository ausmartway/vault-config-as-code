resource "vault_aws_auth_backend_role" "test-role" {
  backend              = vault_auth_backend.aws.path
  role                 = "test-role"
  auth_type            = "iam"
  bound_account_ids    = ["711129375688"]
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = "ap-southeast-2"
  token_ttl            = 600
  token_max_ttl        = 1200
  token_policies       = ["default"]
}