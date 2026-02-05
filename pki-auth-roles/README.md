# PKI Authentication Role Configurations

YAML files in this directory define certificate authentication roles that
allow X.509 certificates to authenticate to Vault.

## Required Fields

- `name` - Unique role identifier
- `certificate` - PEM-encoded CA certificate or certificate bundle
- `token_policies` - List of Vault policies to attach

## Optional Fields

- `allowed_common_names` - List of allowed certificate common names
- `allowed_dns_sans` - List of allowed DNS SANs
- `allowed_uri_sans` - List of allowed URI SANs
- `token_ttl` - Token TTL in seconds
- `token_max_ttl` - Maximum token TTL in seconds

## Example

See `example.yaml` for a template.
