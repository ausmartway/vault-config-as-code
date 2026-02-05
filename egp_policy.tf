################################################################################
# ENDPOINT GOVERNING POLICY (EGP)
################################################################################

# Endpoint Governing Policy: Machine Identity Certificate Restriction
#
# Purpose: Prevents lateral movement attacks by ensuring machines can only
# request PKI certificates for their own identity. The certificate common_name
# must match the requesting entity's name.
#
# Security Model:
# - Normal machines: Can only request certificates matching their own identity
# - Trusted orchestrators (e.g., Terraform): Can request certificates for any
#   machine to enable infrastructure automation and certificate provisioning
#
# This policy is applied to the machine-id PKI role path with hard-mandatory
# enforcement, meaning it cannot be bypassed even by root tokens.
resource "vault_egp_policy" "only-allow-machines-to-request-their-own-id" {
  name              = "only-allow-machines-to-request-their-own-id"
  paths             = ["pki_intermediate/issue/machine-id"]
  enforcement_level = "hard-mandatory"

  policy = <<EOT
entity_is_trusted_orchestrator = rule {
	token.display_name is "token-trusted-orchestrator"
}
entity_name_match_request = rule {
	identity.entity.aliases[0].name is request.data.common_name
}
if entity_is_trusted_orchestrator {
	print("trace:Request.data:", request.data)
	print("trace:Token.display_name:", token.display_name)
} else {
	print("trace:Request.data:", request.data)
	print("trace:identity.entity.name:", identity.entity.name)
	if not entity_name_match_request {
		print("Requestors entity name ", identity.entity.aliases[0].name, " does not match requested machine id ", request.data.common_name)
	}
}
main = rule {
	(entity_is_trusted_orchestrator or entity_name_match_request)
}
EOT
}