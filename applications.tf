locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputappvars = [for f in fileset(path.module, "applications/{app}*.yaml") : jsondecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the appid key from my example YAML files
  inputappmap = { for app in toset(local.inputappvars) : app.appid => app }
}


module "applications" {
  source      = "ausmartway/kv-for-application/vault"
  version     = "0.3.1"
  for_each    = local.inputappmap
  appname     = each.value.appid
  enviroments = each.value.enviroments
}
