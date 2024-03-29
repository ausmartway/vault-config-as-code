locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputawsauthrolevars = [for f in fileset(path.module, "awsauthroles/{awsauth}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the role key from my example YAML files
  inputawsauthrolemap = { for awsauthrole in toset(local.inputawsauthrolevars) : awsauthrole.role => awsauthrole }
}


resource "vault_aws_auth_backend_role" "aws-role" {
  for_each  = local.inputawsauthrolemap
  role      = each.value.role
  backend   = each.value.backend
  auth_type = "iam"

  # Enable below so that HCP can validate iam from other account.

  resolve_aws_unique_ids = false

  bound_account_ids               = each.value.bound_account_ids
  bound_ec2_instance_ids          = each.value.bound_ec2_instance_ids
  bound_iam_instance_profile_arns = each.value.bound_iam_instance_profile_arns
  bound_iam_principal_arns        = each.value.bound_iam_principal_arns
  bound_regions                   = each.value.bound_regions
  bound_subnet_ids                = each.value.bound_subnet_ids
  bound_vpc_ids                   = each.value.bound_vpc_ids
  inferred_entity_type            = each.value.inferred_entity_type
  inferred_aws_region             = each.value.inferred_aws_region
  token_ttl                       = each.value.token_ttl
  token_max_ttl                   = each.value.token_max_ttl
  token_policies                  = each.value.token_policies
  depends_on = [
    vault_auth_backend.aws
  ]
}