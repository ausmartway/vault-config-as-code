# AWS Auth Role Configurations

YAML files in this directory define AWS IAM authentication roles that allow
AWS services to authenticate to Vault using their IAM credentials.

## Required Fields

- `role` - Unique role identifier
- `auth_type` - Authentication type (e.g., `iam`, `ec2`)
- `bound_iam_principal_arn` - ARN of allowed IAM principal

## Optional Fields

- `token_policies` - List of Vault policies to attach
- `token_ttl` - Token TTL in seconds
- `token_max_ttl` - Maximum token TTL in seconds

## Example

See `example.yaml` for a template.
