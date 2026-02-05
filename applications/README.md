# Application Configurations

YAML files in this directory define application KV mounts and policies.

## Required Fields

- `appid` - Unique application identifier
- `name` - Human-readable application name
- `contact` - Owner email address
- `environments` - List of environments (e.g., dev, production)

## Optional Fields

- `enable_approle` - Enable AppRole authentication (default: false)

## Example

See `example.yaml` for a template.
