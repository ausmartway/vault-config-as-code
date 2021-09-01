locals {
  # Take a directory of JSON files, read each one and bring them in to Terraform's native data set
  inputawsauthrolevars = [for f in fileset(path.module, "awsauthroles/{awsauth}*.json") : jsondecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example JSON files
  inputawsauthrolemap = { for awsauthrole in toset(local.inputawsauthrolevars) : awsauthrole.name => awsauthrole }
}


resource "vault_aws_auth_backend_role" "test-role" {
  for_each                        = local.inputawsauthrolemap
  role                            = each.value.role
  backend                         = each.value.backend
  auth_type                       = "iam"
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
}