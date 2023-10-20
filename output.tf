output pki_root_cert {
  value       = vault_pki_secret_backend_root_cert.self-signing-cert.certificate
  sensitive   = false
  description = "the certificate of pki_root default issuer"
}

output pki_intermediate_cert {
  value       = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
  sensitive   = false
  description = "the certificate of pki_intermediate default issuer"
}
