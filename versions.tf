terraform {
  required_version = ">= 1.10"

  required_providers {
    # Update these to reflect the actual requirements of your module
    vault = {
      version = ">= 4.5.0"
    }
  }
}