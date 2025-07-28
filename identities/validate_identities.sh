#!/bin/bash

# Identity YAML Validation Script
# This script validates all YAML files in the identities folder against their schemas
# Requires: yq (YAML processor) and ajv-cli (JSON Schema validator)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IDENTITIES_DIR="${1:-.}"
TEMP_DIR=$(mktemp -d)
EXIT_CODE=0

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo -e "${BLUE}Identity YAML Validation Tool${NC}"
echo "========================================"

# Check if required tools are installed
check_dependencies() {
    echo "Checking dependencies..."
    
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}❌ yq is not installed. Please install it first:${NC}"
        echo "  brew install yq"
        echo "  or visit: https://github.com/mikefarah/yq"
        exit 1
    fi
    
    if ! command -v ajv &> /dev/null; then
        echo -e "${RED}❌ ajv-cli is not installed. Please install it first:${NC}"
        echo "  npm install -g ajv-cli"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies found${NC}"
}

# Convert YAML schema to JSON for ajv
convert_schema() {
    local schema_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$schema_file" ]]; then
        echo -e "${RED}❌ Schema file not found: $schema_file${NC}"
        return 1
    fi
    
    yq eval -o=json "$schema_file" > "$output_file"
    echo -e "${GREEN}✓ Converted schema: $(basename "$schema_file")${NC}"
}

# Validate a single YAML file
validate_file() {
    local yaml_file="$1"
    local schema_file="$2"
    local filename=$(basename "$yaml_file")
    
    # Convert YAML to JSON for validation
    local json_file="$TEMP_DIR/$(basename "$yaml_file" .yaml).json"
    yq eval -o=json "$yaml_file" > "$json_file"
    
    # Validate using ajv (disable format validation to allow custom formats like "date")
    if ajv validate -s "$schema_file" -d "$json_file" --validate-formats=false --verbose 2>/dev/null; then
        echo -e "${GREEN}✓ $filename${NC}"
        return 0
    else
        echo -e "${RED}✗ $filename${NC}"
        # Run again to show detailed errors
        echo -e "${YELLOW}  Validation errors:${NC}"
        ajv validate -s "$schema_file" -d "$json_file" --validate-formats=false --verbose 2>&1 | sed 's/^/    /' || true
        return 1
    fi
}

# Main validation function
main() {
    check_dependencies
    
    if [[ ! -d "$IDENTITIES_DIR" ]]; then
        echo -e "${RED}❌ Identities directory not found: $IDENTITIES_DIR${NC}"
        exit 1
    fi
    
    echo "Working directory: $IDENTITIES_DIR"
    echo ""
    
    # Convert schemas to JSON
    echo "Converting schemas..."
    convert_schema "$IDENTITIES_DIR/schema_application.yaml" "$TEMP_DIR/schema_application.json" || exit 1
    convert_schema "$IDENTITIES_DIR/schema_human.yaml" "$TEMP_DIR/schema_human.json" || exit 1
    echo ""
    
    # Find all identity YAML files
    application_files=()
    human_files=()
    
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        if [[ "$filename" == application_*.yaml ]]; then
            application_files+=("$file")
        elif [[ "$filename" == human_*.yaml ]]; then
            human_files+=("$file")
        fi
    done < <(find "$IDENTITIES_DIR" -name "*.yaml" -not -name "schema_*" -print0)
    
    total_files=$((${#application_files[@]} + ${#human_files[@]}))
    
    if [[ $total_files -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No identity YAML files found to validate${NC}"
        exit 0
    fi
    
    echo "Validating $total_files identity files..."
    echo "============================================================"
    
    # Validate application files
    if [[ ${#application_files[@]} -gt 0 ]]; then
        echo -e "${BLUE}Application Identities:${NC}"
        for file in "${application_files[@]}"; do
            if ! validate_file "$file" "$TEMP_DIR/schema_application.json"; then
                EXIT_CODE=1
            fi
        done
        echo ""
    fi
    
    # Validate human files
    if [[ ${#human_files[@]} -gt 0 ]]; then
        echo -e "${BLUE}Human Identities:${NC}"
        for file in "${human_files[@]}"; do
            if ! validate_file "$file" "$TEMP_DIR/schema_human.json"; then
                EXIT_CODE=1
            fi
        done
        echo ""
    fi
    
    # Print summary
    echo "============================================================"
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}🎉 All identity files are valid!${NC}"
    else
        echo -e "${RED}❌ Some identity files have validation errors.${NC}"
        echo -e "${YELLOW}Please fix the errors above and run validation again.${NC}"
    fi
    
    exit $EXIT_CODE
}

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [identities_directory]"
    echo ""
    echo "Validates all YAML files in the identities folder against their schemas."
    echo ""
    echo "Arguments:"
    echo "  identities_directory    Directory containing identity YAML files (default: current directory)"
    echo ""
    echo "Dependencies:"
    echo "  yq          - YAML processor (brew install yq)"
    echo "  ajv-cli     - JSON Schema validator (npm install -g ajv-cli)"
    echo ""
    echo "Examples:"
    echo "  $0                      # Validate files in current directory"
    echo "  $0 /path/to/identities  # Validate files in custom directory"
    exit 0
fi

main
