locals {
  # Take a directory of JSON files, read each one and bring them in to Terraform's native data set
  inputappvars = [ for f in fileset(path.module, "applications/{app}*.json") : jsondecode(file(f)) ]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example JSON files
  inputappmap = {for app in toset(local.inputappvars): app.appid => app}
}


module "applications" {
  source  = "ausmartway/kv-for-application/vault"
  version = "0.3.1"
  for_each = local.inputappmap
  appname = each.value.appid
  enviroments=each.value.enviroments
}
