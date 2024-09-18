# vault-config-as-code

This is a repository showing how to manage Hashicorp Vault configuration using Hashicorp Terraform.

## Challendges

Vaullt is a stateful application, meaning it need to preserv it's configurations into it's backend storage. Vault can be configured via the UI, CLI or API. However, these methods are not ideal for managing configuration in a version controlled way. This repository shows how to manage Vault configuration using Terraform.

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. In essense, it is a tool that converts what you want to CRUD operations on the target system, and store the state in it's statefile.

## Use Cases implimented

### Enable and configure the KV secrets engine

### Enable and configure the Transit secrets engine

### Enable and configure the pki secrets engine

#### Using PKI secrets engine, impliment a Machine Identity service

### 4.Enable and configure the Identity secrets engine
