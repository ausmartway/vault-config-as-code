terraform {
  required_version = "1.10.4"

  required_providers {
    # Update these to reflect the actual requirements of your module
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.5.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
  }
}