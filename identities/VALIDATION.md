# Identity YAML Validation Tools

This directory contains validation tools to ensure all identity YAML files conform to their respective schemas.

## Available Validation Scripts

### 1. Simple Python Validator (`validate_simple.py`) ⭐ **Recommended**

A lightweight validator that uses only built-in Python libraries and the `yq` tool.

**Prerequisites:**
- `yq` (YAML processor): `brew install yq`
- Python 3.6+

**Usage:**
```bash
## 🚀 Quick Start

```bash
# From the identities directory (recommended)
cd identities
chmod +x validate_simple.py
./validate_simple.py

# From the project root (alternative)
cd identities && ./validate_simple.py
```
```

**Features:**
- ✅ No Python dependencies to install
- ✅ Fast and lightweight
- ✅ Clear error messages
- ✅ Validates required fields and structure
- ✅ Checks environment enum values
- ✅ Validates data types

### 2. Full Python Validator (`validate_identities.py`)

A comprehensive validator using JSON Schema validation.

**Prerequisites:**
- Python 3.6+
- `pip install pyyaml jsonschema` (or use requirements.txt)

**Usage:**
```bash
# Install dependencies (if needed)
pip install -r requirements.txt

# From the identities directory
cd identities
./validate_identities.py

# From project root
./identities/validate_identities.py --dir identities
```

**Features:**
- ✅ Full JSON Schema validation
- ✅ Detailed validation error messages
- ✅ Comprehensive type checking
- ✅ Pattern validation (emails, URLs, etc.)
- ✅ Schema validation

### 3. Shell Script Validator (`validate_identities.sh`)

A bash script version using external tools.

**Prerequisites:**
- `yq`: `brew install yq`
- `ajv-cli`: `npm install -g ajv-cli`

**Usage:**
```bash
# From the identities directory
./validate_identities.sh

# Validate files in a custom directory
./validate_identities.sh /path/to/identities

# Show help
./validate_identities.sh --help
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
  github: "username"            # Non-empty string
  role: "job-title"             # Non-empty string
  team: "team-name"             # Non-empty string

authentication:
  pki: "name.domain"            # Non-empty string

policies:
  identity_policies:            # Non-empty list
    - "policy-name"
```

## Common Validation Errors

### Missing Required Fields
```
❌ Missing required section: metadata
❌ Missing required identity field: name
❌ Missing required authentication field: pki
```

### Invalid Values
```
❌ Invalid environment: prod. Must be one of: [development, staging, production]
❌ identity_policies cannot be empty
❌ identity_policies must be a list
```

### Structure Issues
```
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
      run: ./identities/validate_simple.py
```

### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit
cd "$(git rev-parse --show-toplevel)"
if [ -f "identities/validate_simple.py" ]; then
    echo "Validating identity YAML files..."
    cd identities && ./validate_simple.py
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
	@cd identities && ./validate_simple.py

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
   chmod +x identities/validate_simple.py
   chmod +x identities/validate_identities.py
   chmod +x identities/validate_identities.sh
   ```

4. **Files not found**
   - Ensure you're running from the project root
   - Check that `identities/` directory exists
   - Verify schema files are present

### Debug Mode

For detailed debugging, you can:

1. Check individual files manually:
   ```bash
   yq eval identities/application_example.yaml
   ```

2. Validate JSON conversion:
   ```bash
   yq eval -o=json identities/application_example.yaml | jq .
   ```

3. Check schema syntax:
   ```bash
   yq eval identities/schema_application.yaml
   ```

## Best Practices

1. **Always validate before committing** - Set up pre-commit hooks
2. **Run validation in CI/CD** - Prevent invalid files from merging
3. **Use the simple validator for quick checks** - Faster feedback loop
4. **Use the full validator for comprehensive checks** - Better error messages
5. **Keep schemas up to date** - Update validation rules as requirements change

## File Organization

```
vault-config-as-code/
├── identities/                      # ⭐ All identity-related files
│   ├── schema_application.yaml      # Application schema
│   ├── schema_human.yaml           # Human schema
│   ├── application_*.yaml          # Application identity files
│   ├── human_*.yaml                # Human identity files
│   ├── validate_simple.py          # ⭐ Recommended validator
│   ├── validate_identities.py      # Full JSON Schema validator
│   ├── validate_identities.sh      # Shell script validator
│   ├── requirements.txt            # Python dependencies
│   ├── VALIDATION.md               # This validation guide
│   └── README.md                   # Schema documentation
└── [other terraform files...]      # Main Terraform configuration
```
