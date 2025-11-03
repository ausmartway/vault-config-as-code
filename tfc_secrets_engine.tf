variable "tfc_token" {
  type        = string
  description = "A TFC/TFE token that is used for management purposes"
}

resource "vault_terraform_cloud_secret_backend" "terraform_cloud" {
  backend     = "terraform"
  description = "Manages the Terraform Cloud backend"
  token       = var.tfc_token
}
