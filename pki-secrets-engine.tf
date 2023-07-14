// //pki root CA secret engine
resource "vault_mount" "pki_root" {
  path                      = "pki_root"
  type                      = "pki"
  default_lease_ttl_seconds = 3600 * 24 * 31 * 13     //13 Months
  max_lease_ttl_seconds     = 3600 * 24 * 31 * 12 * 5 //3 Years
}
resource "vault_pki_secret_backend_root_cert" "self-signing-cert" {
  backend              = vault_mount.pki_root.path
  type                 = "internal"
  common_name          = "Root CA"
  ttl                  = 3600 * 24 * 31 * 12 * 5 //5 Years
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "${var.customername} Orgnisation Unit"
  organization         = "${var.customername} Demo Org"
}

resource "vault_pki_secret_backend_issuer" "root-issuer" {
  backend     = vault_pki_secret_backend_root_cert.self-signing-cert.backend
  issuer_ref  = vault_pki_secret_backend_root_cert.self-signing-cert.issuer_id
  issuer_name = "root-issuer"
}


resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.pki_root.path
  issuing_certificates    = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/v1/${vault_mount.pki_root.path}/crl"]
}

//pki intermediate CA secret engine
resource "vault_mount" "pki_intermediate" {
  depends_on                = [vault_pki_secret_backend_root_cert.self-signing-cert]
  path                      = "pki_intermediate"
  type                      = "pki"
  default_lease_ttl_seconds = 2678400  //Default expiry of the certificates signed by this CA - 31 days
  max_lease_ttl_seconds     = 3600 * 24 * 31 * 12 * 5 //3 Years 
}
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on  = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend     = vault_mount.pki_intermediate.path
  type        = "internal"
  common_name = "ca.${var.customername}.hashicorp.demo"
}
resource "vault_pki_secret_backend_root_sign_intermediate" "root" {
  depends_on           = [vault_pki_secret_backend_root_cert.self-signing-cert]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  ttl                  = 3600 * 24 * 31 * 12 * 5 //5 Years
  common_name          = "ca.${var.customername}.hashicorp.demo"
  exclude_cn_from_sans = true
  ou                   = "${var.customername} Orgnisation Unit"
  organization         = "${var.customername} Demo Org"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  depends_on  = [vault_pki_secret_backend_config_urls.config_urls_int]
  backend     = vault_mount.pki_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.root.certificate
}

resource "vault_pki_secret_backend_config_urls" "config_urls_int" {
  backend                 = vault_mount.pki_intermediate.path
  issuing_certificates    = ["${var.vault_url}/v1/${vault_mount.pki_intermediate.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/v1/${vault_mount.pki_intermediate.path}/crl"]
}


resource "vault_auth_backend" "cert" {
  path = "cert"
  type = "cert"
}

# resource "vault_cert_auth_backend_role" "cert" {
#     name           = "foo"
#     certificate    = file("/path/to/certs/ca-cert.pem")
#     backend        = vault_auth_backend.cert.path
#     allowed_names  = ["foo.example.org", "baz.example.org"]
#     token_ttl      = 300
#     token_max_ttl  = 600
#     token_policies = ["foo"]
# }

resource "vault_pki_secret_backend_role" "vault-self" {
  backend = vault_mount.pki_intermediate.path
  name    = "vault-self"
  ttl     = 94608000 #3 years
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment"
  ]
  allow_any_name = true
}