#!/usr/bin/env python3
"""
Validation script for identity YAML files against their JSON schemas.

This script validates all YAML files in the identities folder against their
corresponding schemas to ensure they follow the correct structure and format.
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class IdentityValidator:
    """Validates identity YAML files against their JSON schemas."""
    
    def __init__(self, identities_dir: str = "."):
        """
        Initialize the validator.
        
        Args:
            identities_dir: Path to the identities directory
        """
        self.identities_dir = Path(identities_dir)
        self.schemas = {}
        self.errors = []
        self.warnings = []
        
    def check_dependencies(self) -> bool:
        """Check if required dependencies are available."""
        try:
            # Check for yq (required)
            subprocess.run(['yq', '--version'], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.errors.append("yq is not installed. Please install it with: brew install yq")
            return False
            
        # Check for optional Python modules
        try:
            import yaml
            import jsonschema
            print("✓ Full validation mode (with pyyaml and jsonschema)")
        except ImportError:
            print("⚠️  Fallback validation mode (using yq only)")
            print("   For full validation, install: pip install pyyaml jsonschema")
            
        return True
        
    def load_schemas(self) -> bool:
        """
        Load all schema files from the identities directory.
        
        Returns:
            True if schemas loaded successfully, False otherwise
        """
        schema_files = {
            'application': self.identities_dir / 'schema_application.yaml',
            'human': self.identities_dir / 'schema_human.yaml'
        }
        
        for schema_type, schema_path in schema_files.items():
            if not schema_path.exists():
                self.errors.append(f"Schema file not found: {schema_path}")
                return False
                
            try:
                # Use yq to convert YAML to JSON
                result = subprocess.run(
                    ['yq', 'eval', '-o=json', str(schema_path)],
                    capture_output=True,
                    text=True,
                    check=True
                )
                schema_data = json.loads(result.stdout)
                
                # Validate that the schema itself is valid
                try:
                    import jsonschema
                    jsonschema.Draft7Validator.check_schema(schema_data)
                except ImportError:
                    pass  # Skip schema validation if jsonschema not available
                    
                self.schemas[schema_type] = schema_data
                print(f"✓ Loaded {schema_type} schema: {schema_path}")
            except subprocess.CalledProcessError as e:
                self.errors.append(f"Error parsing schema {schema_path}: {e.stderr}")
                return False
            except json.JSONDecodeError as e:
                self.errors.append(f"JSON decode error for schema {schema_path}: {e}")
                return False
            except Exception as e:
                self.errors.append(f"Error loading schema {schema_path}: {e}")
                return False
                
        return True
    
    def determine_schema_type(self, file_path: Path) -> Optional[str]:
        """
        Determine which schema to use based on the filename.
        
        Args:
            file_path: Path to the YAML file
            
        Returns:
            Schema type ('application' or 'human') or None if undetermined
        """
        filename = file_path.name.lower()
        
        if filename.startswith('application_'):
            return 'application'
        elif filename.startswith('human_'):
            return 'human'
        elif filename.startswith('schema_'):
            return None  # Skip schema files
        else:
            self.warnings.append(f"Cannot determine schema type for file: {file_path}")
            return None
    
    def validate_file(self, file_path: Path) -> Tuple[bool, List[str]]:
        """
        Validate a single YAML file against its schema.
        
        Args:
            file_path: Path to the YAML file to validate
            
        Returns:
            Tuple of (is_valid, list_of_errors)
        """
        schema_type = self.determine_schema_type(file_path)
        if not schema_type:
            return True, []  # Skip files we can't determine schema for
            
        if schema_type not in self.schemas:
            return False, [f"No schema available for type: {schema_type}"]
        
        try:
            # Load and parse the YAML file using yq
            result = subprocess.run(
                ['yq', 'eval', '-o=json', str(file_path)],
                capture_output=True,
                text=True,
                check=True
            )
            data = json.loads(result.stdout)
            
            # Try to validate against schema if jsonschema is available
            try:
                import jsonschema
                jsonschema.validate(instance=data, schema=self.schemas[schema_type])
                return True, []
            except ImportError:
                # Fall back to basic validation if jsonschema not available
                return self._basic_validate(data, schema_type)
            except jsonschema.ValidationError as e:
                # Format validation error message
                error_path = " -> ".join([str(p) for p in e.absolute_path]) if e.absolute_path else "root"
                error_msg = f"Validation error at '{error_path}': {e.message}"
                return False, [error_msg]
                
        except subprocess.CalledProcessError as e:
            return False, [f"YAML parsing error: {e.stderr}"]
        except json.JSONDecodeError as e:
            return False, [f"JSON decode error: {e}"]
        except Exception as e:
            return False, [f"Unexpected error: {e}"]
    
    def _basic_validate(self, data: Dict, schema_type: str) -> Tuple[bool, List[str]]:
        """Basic validation when jsonschema is not available."""
        errors = []
        
        # Check required top-level sections
        required_sections = ['metadata', 'identity', 'authentication', 'policies']
        for section in required_sections:
            if section not in data:
                errors.append(f"Missing required section: {section}")
        
        return len(errors) == 0, errors
    
    def validate_all_files(self) -> bool:
        """
        Validate all YAML files in the identities directory.
        
        Returns:
            True if all files are valid, False otherwise
        """
        if not self.identities_dir.exists():
            self.errors.append(f"Identities directory not found: {self.identities_dir}")
            return False
        
        # Find all YAML files
        yaml_files = list(self.identities_dir.glob("*.yaml")) + list(self.identities_dir.glob("*.yml"))
        
        # Filter out schema files
        identity_files = [f for f in yaml_files if not f.name.startswith('schema_')]
        
        if not identity_files:
            self.warnings.append("No identity YAML files found to validate")
            return True
        
        print(f"\nValidating {len(identity_files)} identity files...")
        print("=" * 60)
        
        all_valid = True
        validation_results = []
        
        for file_path in sorted(identity_files):
            is_valid, file_errors = self.validate_file(file_path)
            validation_results.append((file_path, is_valid, file_errors))
            
            if is_valid:
                print(f"✓ {file_path.name}")
            else:
                print(f"✗ {file_path.name}")
                for error in file_errors:
                    print(f"    {error}")
                all_valid = False
        
        return all_valid
    
    def run_validation(self) -> int:
        """
        Run the complete validation process.
        
        Returns:
            Exit code (0 for success, 1 for failure)
        """
        print("Identity YAML Validation Tool")
        print("=" * 40)
        
        # Check dependencies
        if not self.check_dependencies():
            print("\n❌ Dependencies not met:")
            for error in self.errors:
                print(f"  {error}")
            return 1
        
        # Load schemas
        if not self.load_schemas():
            print("\n❌ Failed to load schemas:")
            for error in self.errors:
                print(f"  {error}")
            return 1
        
        # Validate files
        all_valid = self.validate_all_files()
        
        # Print warnings
        if self.warnings:
            print(f"\n⚠️  Warnings:")
            for warning in self.warnings:
                print(f"  {warning}")
        
        # Print summary
        print("\n" + "=" * 60)
        if all_valid:
            print("🎉 All identity files are valid!")
            return 0
        else:
            print("❌ Some identity files have validation errors.")
            print("Please fix the errors above and run validation again.")
            return 1


def main():
    """Main entry point for the validation script."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Validate identity YAML files against their schemas",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python validate_identities.py                    # Validate files in current directory
  python validate_identities.py --dir /path/to/identities  # Custom directory
        """
    )
    
    parser.add_argument(
        "--dir", "-d",
        default=".",
        help="Directory containing identity YAML files (default: current directory)"
    )
    
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    
    args = parser.parse_args()
    
    # Set up the validator
    validator = IdentityValidator(args.dir)
    
    # Run validation
    exit_code = validator.run_validation()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
