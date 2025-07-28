# Identity Configuration Files

This directory contains structured YAML configuration files for defining Vault identities, including both application and human identities.

## Structure Overview

### Schema Files

- `schema_application.yaml` - JSON Schema for application identity configuration
- `schema_human.yaml` - JSON Schema for human identity configuration

### Identity Files

- `application_*.yaml` - Application identity definitions
- `human_*.yaml` - Human identity definitions

### Validation Scripts

- `validate_identities.py` - Full-featured Python validator
- `validate_identities.sh` - Shell script validator

## File Structure

All identity files follow a consistent hierarchical structure:

### Application Identity Structure

```yaml
$schema: "./schema_application.yaml"

metadata:
  version: "1.0.0"                    # Semantic version
  created_date: "2025-07-28"          # Creation date (YYYY-MM-DD)
  description: "Brief description"     # Purpose description

identity:
  name: "Application Name"             # Human-readable name
  contact: "email@domain.com"          # Contact email
  environment: "production"            # Environment (development/staging/production)
  business_unit: "unit_name"           # Owning business unit

authentication:
  aws_auth_role: "role-name"           # AWS authentication role
  pki: "cert.machine-id.domain"       # PKI certificate identifier
  github_repo: "owner/repo"            # GitHub repository (optional)
  tfc_workspace: "org:proj:workspace"  # Terraform Cloud workspace (optional)

policies:
  identity_policies:                   # List of Vault policies
    - "policy-name"
```

### Human Identity Structure

```yaml
$schema: "./schema_human.yaml"

metadata:
  version: "1.0.0"                    # Semantic version
  created_date: "2025-07-28"          # Creation date (YYYY-MM-DD)
  description: "Brief description"     # Purpose description

identity:
  name: "Full Name"                    # Person's full name
  email: "email@domain.com"            # Email address
  role: "job-title"                    # Job role
  team: "team-name"                    # Team or department

authentication:
  pki: "name.human-id.domain"          # PKI certificate identifier
  github: "username"                   # GitHub username

policies:
  identity_policies:                   # List of Vault policies
    - "policy-name"
```

## Schema Validation

Each identity file includes a schema reference at the top:

- Application identities: `$schema: "./schema_application.yaml"`
- Human identities: `$schema: "./schema_human.yaml"`

The schemas provide:

- **Type validation** - Ensures correct data types
- **Required field enforcement** - Validates all mandatory fields are present
- **Format validation** - Validates emails, patterns, and enums
- **Documentation** - Describes each field's purpose

## Benefits of This Structure

1. **Consistency** - All files follow the same hierarchical structure
2. **Validation** - Schema validation prevents configuration errors
3. **Maintainability** - Clear separation of concerns with logical grouping
4. **Documentation** - Self-documenting with descriptions and examples
5. **Versioning** - Built-in version tracking for configuration changes
6. **Type Safety** - Strong typing prevents common configuration mistakes

## Usage Guidelines

1. **Creating New Identities**:
   - Copy an existing file as a template
   - Update all fields according to the schema
   - Ensure the schema reference is correct

2. **Modifying Existing Identities**:
   - Update the version number using semantic versioning
   - Validate against the schema before committing

3. **Schema Updates**:
   - Update schema files when adding new fields
   - Maintain backward compatibility when possible
   - Update all existing files to match new schema requirements

---

## Validation Tools

This directory contains validation tools to ensure all identity YAML files conform to their respective schemas.

## Available Validation Scripts

### 1. Python Validator (`validate_identities.py`) ⭐ **Recommended**

A comprehensive validator that can work with or without additional Python dependencies.

**Prerequisites:**

- `yq` (YAML processor): `brew install yq`
- Python 3.6+
- Optional: `pip install pyyaml jsonschema` for full JSON Schema validation

**Usage:**

```bash
# From this directory (recommended)
./validate_identities.py

# Show help
./validate_identities.py --help
```

**Features:**

- ✅ Works with or without additional dependencies (graceful fallback)
- ✅ Full JSON Schema validation (when dependencies available)
- ✅ Comprehensive error messages
- ✅ Command-line interface with options
- ✅ Validates required fields and structure

### 2. Shell Script Validator (`validate_identities.sh`)

A bash script version using external tools.

**Prerequisites:**

- `yq`: `brew install yq`
- `ajv-cli`: `npm install -g ajv-cli`

**Usage:**

```bash
# Run validation
./validate_identities.sh

# Show help
./validate_identities.sh --help
```

## 🚀 Quick Start

```bash
# From the identities directory (recommended)
cd identities
chmod +x validate_identities.py
./validate_identities.py
```

## Validation Rules

### Application Identity Files (`application_*.yaml`)

**Required Structure:**

```yaml
$schema: "./schema_application.yaml"

metadata:
  version: "1.0.0"              # Semantic version (x.y.z)
  created_date: "2025-07-28"    # Date (YYYY-MM-DD)
  description: "Description"     # Non-empty string

identity:
  name: "App Name"              # Non-empty string
  contact: "email@domain.com"   # Valid email
  environment: "production"     # development|staging|production
  business_unit: "unit"         # Non-empty string

authentication:
  aws_auth_role: "role-name"    # Non-empty string
  pki: "cert.domain"            # Non-empty string
  github_repo: "owner/repo"     # Optional: GitHub repo format
  tfc_workspace: "workspace"    # Optional: TFC workspace

policies:
  identity_policies:            # Non-empty list
    - "policy-name"
```

### Human Identity Files (`human_*.yaml`)

**Required Structure:**

```yaml
$schema: "./schema_human.yaml"

metadata:
  version: "1.0.0"              # Semantic version (x.y.z)
  created_date: "2025-07-28"    # Date (YYYY-MM-DD)
  description: "Description"     # Non-empty string

identity:
  name: "Full Name"             # Non-empty string
  email: "email@domain.com"     # Valid email
  role: "job-title"             # Non-empty string
  team: "team-name"             # Non-empty string

authentication:
  pki: "name.domain"            # Non-empty string
  github: "username"            # Non-empty string

policies:
  identity_policies:            # Non-empty list
    - "policy-name"
```

## Common Validation Errors

### Missing Required Fields

```text
❌ Missing required section: metadata
❌ Missing required identity field: name
❌ Missing required authentication field: pki
```

### Invalid Values

```text
❌ Invalid environment: prod. Must be one of: [development, staging, production]
❌ identity_policies cannot be empty
❌ identity_policies must be a list
```

### Structure Issues

```text
❌ Failed to parse YAML file: invalid syntax
❌ Cannot determine type for file: unknown_file.yaml
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Validate Identity Files
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install yq
      run: |
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
    
    - name: Validate Identity Files
      run: ./identities/validate_identities.py
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit
cd "$(git rev-parse --show-toplevel)"
if [ -f "identities/validate_identities.py" ]; then
    echo "Validating identity YAML files..."
    cd identities && ./validate_identities.py
    if [ $? -ne 0 ]; then
        echo "❌ Identity validation failed. Please fix the errors and try again."
        exit 1
    fi
fi
```

### Makefile Integration

```makefile
.PHONY: validate-identities
validate-identities:
	@echo "Validating identity YAML files..."
	@cd identities && ./validate_identities.py

.PHONY: validate-full
validate-full:
	@echo "Running full validation with JSON Schema..."
	@cd identities && ./validate_identities.py

# Run validation before apply
plan: validate-identities
	terraform plan

apply: validate-identities
	terraform apply
```

## Troubleshooting

### Common Issues

1. **`yq not found`**
   ```bash
   brew install yq
   ```

2. **`jsonschema not found`**
   ```bash
   pip install jsonschema pyyaml
   ```

3. **Permission denied**
   ```bash
   chmod +x validate_simple.py
   chmod +x validate_identities.py
   chmod +x validate_identities.sh
   ```

4. **Files not found**
   - Ensure you're running from the identities directory
   - Check that schema files are present
   - Verify YAML files exist

### Debug Mode

For detailed debugging, you can:

1. Check individual files manually:
   ```bash
   yq eval application_example.yaml
   ```

2. Validate JSON conversion:
   ```bash
   yq eval -o=json application_example.yaml | jq .
   ```

3. Check schema syntax:
   ```bash
   yq eval schema_application.yaml
   ```

## Best Practices

1. **Always validate before committing** - Set up pre-commit hooks
2. **Run validation in CI/CD** - Prevent invalid files from merging
3. **Use the Python validator for development** - Fast feedback with graceful fallback
4. **Use the shell validator for CI/CD** - Comprehensive validation with detailed errors
5. **Keep schemas up to date** - Update validation rules as requirements change

## File Organization

```text
vault-config-as-code/
├── identities/                      # ⭐ All identity-related files
│   ├── schema_application.yaml      # Application schema
│   ├── schema_human.yaml           # Human schema
│   ├── application_*.yaml          # Application identity files
│   ├── human_*.yaml                # Human identity files
│   ├── validate_identities.py      # ⭐ Recommended Python validator
│   ├── validate_identities.sh      # Shell script validator
│   ├── requirements.txt            # Python dependencies
│   └── README.md                   # This comprehensive guide
└── [other terraform files...]      # Main Terraform configuration
```
