
locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputnamespacevars = [for f in fileset(path.module, "namespaces/{namespace}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example YAML files
  inputnamespacemap = { for namespace in toset(local.inputnamespacevars) : namespace.name => namespace }
}

module "vault_namespace" {
  source   = "ausmartway/namespace/vault"
  version  = "0.0.3"
  for_each = local.inputnamespacemap
  name     = each.value.name
} 