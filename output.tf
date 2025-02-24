output "pki_root_cert" {
  value       = vault_pki_secret_backend_root_cert.self-signing-cert.certificate
  sensitive   = false
  description = "the certificate of pki_root default issuer"
}

output "pki_intermediate_cert" {
  value       = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
  sensitive   = false
  description = "the certificate of pki_intermediate default issuer"
}

output "ssh_ca_cert" {
  value       = vault_ssh_secret_backend_ca.ssh-ca.public_key
  sensitive   = false
  description = "The public key of the ssh CA"
}

output "superuser_token" {
  value       = vault_token.superuser.client_token
  sensitive   = false
  description = "The superuser token"
}