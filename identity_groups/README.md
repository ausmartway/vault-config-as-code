# Identity Group Configurations

YAML files in this directory define Vault identity groups for organizing
entities and managing access control at scale.

## Required Fields

- `name` - Unique group identifier
- `identity_group_policies` - List of policies attached to the group

## Optional Fields

- `human_identities` - List of human identity names to include
- `application_identities` - List of application identity names to include
- `sub_groups` - List of child group names for hierarchical grouping

## Example

See `example.yaml` for a template.
