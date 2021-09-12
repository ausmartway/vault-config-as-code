variable "vault_url" {
  description = "The URL to vault"
  default     = "http://vault.yulei.aws.hashidemos.io:8200/"
}

variable "azure_tanent_id" {
  type = string
  description="Azure tanent id"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client id"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription id"
}