variable "vault_url" {
  type        = string
  description = "The URL to vault"
  default     = "http://vault.yulei.aws.hashidemos.io:8200/"
}

# variable "customername" {
#   type        = string
#   description = "Name of the customer that this demo is built for"
#   default     = "customer"
# }

# variable "aws_secret_key" {
#   type        = string
#   description = "aws_secret_key"
#   default     = ""
# }

# variable "aws_access_key" {
#   type        = string
#   description = "aws_access_key"
#   default     = ""
# }

variable "enviroment" {
  type        = string
  description = "enviroment"
  default     = "local"
}
# disable azure

# variable "azure_tanent_id" {
#   type        = string
#   description = "Azure tanent id"
# }

# variable "azure_client_id" {
#   type        = string
#   description = "Azure client id"
# }

# variable "azure_client_secret" {
#   type        = string
#   description = "Azure client secret"
# }

# variable "azure_subscription_id" {
#   type        = string
#   description = "Azure subscription id"
# }