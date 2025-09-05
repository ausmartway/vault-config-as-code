# vault-config-as-code

This is a repository showing how to manage Hashicorp Vault configuration using Hashicorp Terraform.

## Challenges

Vault is a stateful application, meaning it needs to preserve its configurations into its backend storage. Vault can be configured via the UI, CLI or API. However, these methods are not ideal for managing configuration in a version controlled way. This repository shows how to manage Vault configuration using Terraform.

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. In essence, it is a tool that converts what you want to CRUD operations on the target system, and store the state in its statefile.

## Use Cases Implemented

### KV Secrets Engine
Application-specific secret storage with environment-based separation using Terraform modules for multi-tenant secret management. Each application gets dedicated KV v2 mounts per environment with granular policies for secret providers and consumers.

### Transit Secrets Engine
Encryption-as-a-Service for protecting streaming data platforms (Kafka, Kinesis, Pub/Sub) with centralized key management, seamless rotation, and DEK patterns for large payloads. Eliminates the need for applications to directly manage encryption keys while providing consistent encryption across platforms.

### PKI Secrets Engine
Two-tier certificate authority infrastructure (root + intermediate CA) enabling certificate-based machine/human identity verification and mTLS authentication. Supports automated certificate lifecycle management with configurable TTLs and revocation capabilities.

### Identity Engine
OIDC identity provider generating cryptographically signed JWT tokens with rich metadata for zero-trust authentication. Supports API gateway integration and SPIFFE-compliant workload identity with RS256 signing, automatic key rotation, and audience-specific token validation.

### Authentication Methods
Multi-modal authentication supporting GitHub OAuth for human users, AWS IAM roles for cloud services, AppRole for application authentication, and PKI certificate-based authentication for machine identities.

### Namespace Management
Multi-tenant isolation with delegated administration and environment-specific policy enforcement. Each namespace provides complete administrative control while maintaining security boundaries between tenants.
