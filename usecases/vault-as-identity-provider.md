
# Vault as Identity Provider

Vault can be used as an identity provider to manage and authenticate users, providing a secure way to handle user credentials and access control. This use case typically involves integrating Vault with existing identity systems or applications to centralize authentication and authorization.

## steps

1. Login to Vault
2. Request a vault access token from Vault
3. Use the access token to request a signed JWT from Vault

```bash
curl \
    --header "X-Vault-Token: $(vault login -field=token -method=github token=$GITHUB_TOKEN)" \
    --request GET \
    --data @usecases/human_idendity.json \
    https://nginx/v1/identity/oidc/token/human_identity \
    | jq .data.token
```

4. Use the signed JWT to authenticate with your application or service
5. Configure your application to trust the JWT issued by Vault
