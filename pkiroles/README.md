# PKI Role Configurations

YAML files in this directory define certificate issuance roles for the PKI
secrets engine. These roles act as templates that control what certificates
can be issued.

## Required Fields

- `name` - Unique role identifier
- `backend` - PKI mount path (typically `pki_intermediate`)
- `ttl` - Default certificate validity period in seconds
- `maxttl` - Maximum certificate validity period in seconds
- `contact` - Owner email address

## Optional Fields

- `allow_any_name` - Allow any common name (default: false)
- `allowed_domains` - List of allowed domain suffixes
- `ou` - Organizational Unit
- `organization` - Organization name
- `country` - Country code
- `province` - State/Province
- `locality` - City
- `street_address` - Street address
- `postal_code` - Postal/ZIP code

## TTL Reference

| Value | Duration |
|-------|----------|
| 604800 | 7 days |
| 2419200 | 28 days |
| 7863400 | ~3 months |
| 24819200 | ~13 months |
| 34214400 | ~13 months |

## Example

See `example.yaml` for a template.
