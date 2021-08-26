locals {
  # Take a directory of JSON files, read each one and bring them in to Terraform's native data set
  inputvars = [ for f in fileset(path.module, "applications/[app]*.json") : jsondecode(file(f)) ]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the name key from my example JSON files
  inputmap = {for app in toset(local.inputvars): app.appid => app}
}


module "applications" {
  source  = "github.com/ausmartway/terraform-specialcustomer-vault-app-module"
  version = "0.3.1"
  for_each = local.inputmap
  appname = each.value.appid
  enviroments=each.value.enviroments
}