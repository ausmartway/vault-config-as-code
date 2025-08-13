# Modern Data Sources Pattern for YAML Configuration Loading
# This file centralizes all YAML file loading and provides a single source of truth

# Load all YAML configuration files using data sources
data "local_file" "config_files" {
  for_each = toset([
    for f in fileset(path.module, "{applications,awsauthroles,namespaces,pki-auth-roles,identity_groups,pkiroles,identities}/*.yaml") : f
    if f != "applications/example.yaml" &&
    f != "awsauthroles/example.yaml" &&
    f != "namespaces/example.yaml" &&
    f != "pki-auth-roles/example.yaml" &&
    f != "identity_groups/example.yaml" &&
    f != "pkiroles/example.yaml" &&
    f != "identities/example.yaml"
  ])
  filename = "${path.module}/${each.value}"
}

locals {
  # Parse all configs with error handling and validation
  all_configs = {
    for path, file in data.local_file.config_files :
    path => try(yamldecode(file.content), null)
  }

  # Filter out any configs that failed to parse
  valid_configs = {
    for path, config in local.all_configs :
    path => config if config != null
  }

  # Group configurations by type based on directory structure
  configs_by_type = {
    applications    = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "applications/") }
    awsauthroles    = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "awsauthroles/") }
    namespaces      = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "namespaces/") }
    pki_auth_roles  = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "pki-auth-roles/") }
    identity_groups = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "identity_groups/") }
    pkiroles        = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "pkiroles/") }
    identities      = { for path, config in local.valid_configs : trimsuffix(basename(path), ".yaml") => config if startswith(path, "identities/") }
  }

  # Transform configurations to match expected data structures

  # Applications: keyed by appid
  applications_map = {
    for filename, config in local.configs_by_type.applications :
    config.appid => config
  }

  # AWS Auth Roles: keyed by role
  aws_auth_roles_map = {
    for filename, config in local.configs_by_type.awsauthroles :
    config.role => config
  }

  # Namespaces: keyed by name
  namespaces_map = {
    for filename, config in local.configs_by_type.namespaces :
    config.name => config
  }

  # PKI Auth Roles: keyed by name
  pki_auth_roles_map = {
    for filename, config in local.configs_by_type.pki_auth_roles :
    config.name => config
  }

  # Identity Groups: keyed by name
  identity_groups_map = {
    for filename, config in local.configs_by_type.identity_groups :
    config.name => config
  }

  # PKI Roles: keyed by name
  pki_roles_map = {
    for filename, config in local.configs_by_type.pkiroles :
    config.name => config
  }

  # Identities: split by type and keyed appropriately
  human_identities_map = {
    for filename, config in local.configs_by_type.identities :
    config.identity.name => config
    if startswith(filename, "human_")
  }

  application_identities_map = {
    for filename, config in local.configs_by_type.identities :
    config.identity.name => config
    if startswith(filename, "application_")
  }


  # Filtered identity maps for specific authentication types
  human_with_github = {
    for k, v in local.human_identities_map :
    k => v if try(v.authentication.github, null) != null && v.authentication.github != ""
  }

  human_with_pki = {
    for k, v in local.human_identities_map :
    k => v if try(v.authentication.pki, null) != null && v.authentication.pki != ""
  }

  app_with_github_repo = {
    for k, v in local.application_identities_map :
    k => v if try(v.authentication.github_repo, null) != null && v.authentication.github_repo != ""
  }

  app_with_pki = {
    for k, v in local.application_identities_map :
    k => v if try(v.authentication.pki, null) != null && v.authentication.pki != ""
  }

  app_with_tfc_workspace = {
    for k, v in local.application_identities_map :
    k => v if try(v.authentication.tfc_workspace, null) != null && v.authentication.tfc_workspace != ""
  }
}

# Output for debugging and validation
output "config_summary" {
  value = {
    total_configs_loaded   = length(local.valid_configs)
    applications_count     = length(local.applications_map)
    aws_auth_roles_count   = length(local.aws_auth_roles_map)
    namespaces_count       = length(local.namespaces_map)
    pki_auth_roles_count   = length(local.pki_auth_roles_map)
    identity_groups_count  = length(local.identity_groups_map)
    pki_roles_count        = length(local.pki_roles_map)
    human_identities_count = length(local.human_identities_map)
    app_identities_count   = length(local.application_identities_map)
  }
  description = "Summary of loaded configurations"
}