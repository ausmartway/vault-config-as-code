variable "vault_url" {
  description = "The URL to vault"
  default     = "http://vault.yulei.aws.hashidemos.io:8200/"
}

<<<<<<< HEAD
variable "customername" {
  description = "Name of the customer that this demo is built for"
  default     = "customer"
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

=======
variable "aws_secret_key" {
  description="aws_secret_key"
}

variable "aws_access_key" {
  description="aws_access_key"
}
# variable "azure_tanent_id" {
#   type        = string
#   description = "Azure tanent id"
# }

# variable "azure_client_id" {
#   type        = string
#   description = "Azure client id"
# }

>>>>>>> 5fadbf49c4e2e0156ad20c0f48e68fa1594c4617
# variable "azure_client_secret" {
#   type        = string
#   description = "Azure client secret"
# }

# variable "azure_subscription_id" {
#   type        = string
#   description = "Azure subscription id"
# }