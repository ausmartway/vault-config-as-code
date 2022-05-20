//github auth backend, as long as you belong to the hashicorp orgnisation, you will be able to login to Vault and get super user previlige using your personal github token.
resource "vault_github_auth_backend" "hashicorp" {
  organization   = "hashicorp"
  token_policies = ["super-user"]
}

resource "vault_policy" "super-user" {
  name   = "super-user"
  policy = <<EOF
 path "*" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
 }
 EOF
}


//aws auth method

resource "vault_auth_backend" "aws" {
  type = "aws"
  path = "aws"
}

resource "vault_aws_auth_backend_client" "aws_client" {
  backend    = vault_auth_backend.aws.path
  access_key = ""
  secret_key = ""
}

# //azure auth method
# resource "vault_auth_backend" "azure" {
#   type = "azure"
#   path = "azure"
# }

# resource "vault_azure_auth_backend_config" "azure_auth_config" {
#   backend       = vault_auth_backend.azure.path
#   tenant_id     = var.azure_tanent_id
#   client_id     = var.azure_client_id
#   client_secret = var.azure_client_secret
#   resource      = "https://vault.hashicorp.com"
# }

# resource "vault_azure_auth_backend_role" "azurerole" {
#   backend                = vault_auth_backend.azure.path
#   role                   = "test-role"
#   bound_subscription_ids = [var.azure_subscription_id]
#   token_ttl              = 300
#   token_max_ttl          = 600
#   token_policies         = []
# }

# //azure secret engine

# resource "vault_azure_secret_backend" "azure" {
#   subscription_id = var.azure_subscription_id
#   tenant_id       = var.azure_tanent_id
#   client_id       = var.azure_client_id
#   client_secret   = var.azure_client_secret
#   environment     = "AzurePublicCloud"
# }

# resource "vault_azure_secret_backend_role" "generated_role" {
#   backend                     = vault_azure_secret_backend.azure.path
#   role                        = "generated_role"
#   ttl                         = 300
#   max_ttl                     = 600

#   azure_roles {
#     role_name = "Reader"
#     scope =  "/subscriptions/${var.subscription_id}/resourceGroups/azure-vault-group"
#   }
# }


//Approle auth method

resource "vault_auth_backend" "approle" {
  type = "approle"
}

# Approle should only be used when there is no better/native authentication, eg, aws/gcp/azure/k8s/ldap.
# The approle roles in this repository will be created by the application module, for each application and enviroments. 
# Below codes are just examples if you want to create approle roles outside of the application module.
#
# resource "vault_approle_auth_backend_role" "example" {
#   backend   = vault_auth_backend.approle.path
#   role_name = "test-role"
#   policies  = ["default", "dev", "prod"]
# }

# resource "vault_approle_auth_backend_role_secret_id" "id" {
#   backend   = vault_auth_backend.approle.path
#   role_name = vault_approle_auth_backend_role.example.role_name
# }

# resource "vault_approle_auth_backend_login" "login" {
#   backend   = vault_auth_backend.approle.path
#   role_id   = vault_approle_auth_backend_role.example.role_id
#   secret_id = vault_approle_auth_backend_role_secret_id.id.secret_id
# }



//transit secret engine
resource "vault_mount" "encryption-as-a-service" {
  path                      = "EaaS"
  type                      = "transit"
  description               = "Encryption/Decryption as a Service for ${var.customername}"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "hashi-encryption-key" {
  backend                = vault_mount.encryption-as-a-service.path
  name                   = "${var.customername}-encryption-key"
  deletion_allowed       = true
  exportable             = false
  allow_plaintext_backup = true
}

//aws secrets engine
resource "vault_aws_secret_backend" "aws" {
  description               = "AWS secrets engine"
  region                    = "ap-southeast-2"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 3600 * 48 // two days
}


resource "vault_aws_secret_backend_role" "iam_manager" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "iam_manager"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "s3_manager" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "s3_manager"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "cicdpipeline" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "cicdpipeline"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOT
}


resource "vault_aws_secret_backend_role" "cicdpipelinests" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "cicdpipelinests"
  credential_type = "federation_token"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOT
}


//Audit device
resource "vault_audit" "auditlog" {
  type = "file"
  options = {
    file_path = "/tmp/vault_audit.log"
  }
}