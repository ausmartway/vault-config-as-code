vault secrets enable kmip
vault write kmip/config listen_addrs=0.0.0.0:5696 server_hostnames=vault.yulei.aws.hashidemos.io
vault read kmip/config
vault read kmip/ca -format=json | jq -r .data.ca_pem >ca-bundle.pem
vault write -f kmip/scope/mongodb
vault list kmip/scope
vault write kmip/scope/mongodb/role/admin operation_all=true
vault list kmip/scope/mongodb/role
vault read kmip/scope/mongodb/role/admin
vault write -format=json kmip/scope/mongodb/role/admin/credential/generate format=pem > credential.json
jq -r .data.certificate < credential.json > cert.pem
jq -r .data.private_key < credential.json > key.pem
vault list kmip/scope/mongodb/role/admin/credential
cat cert.pem key.pem > mongod.pem
copy mongod.pem and ca.pem to mongo server
mongod --dbpath mongodata --enableEncryption --kmipServerName vault.yulei.aws.hashidemos.io --kmipPort 5696 --kmipServerCAFile ca.pem --kmipClientCertificateFile mongod.pem
reference:
https://docs.mongodb.com/manual/tutorial/configure-encryption/
https://learn.hashicorp.com/tutorials/vault/kmip-engine



vault write -f kmip/scope/cassandra
vault list kmip/scope
vault write kmip/scope/cassandra/role/admin operation_all=true
vault write -format=json kmip/scope/cassandra/role/admin/credential/generate format=pem > credential.json
jq -r .data.certificate < credential.json > cassandra-cert.pem
jq -r .data.private_key < credential.json > cassandra-key.pem

split the ca-bundle.pem into intermediate and root ca
//converting key and cert into p12 format
openssl pkcs12 -export -out kmip_keystore.p12 -inkey cassandra-key.pem -in cassandra-cert.pem

create a temp java key store for and import the CA bundle
keytool -importcert -alias rootca -file root-ca-selfsigned.pem -keystore truststore.jks
keytool -importcert -alias intermediate -file intermediate-ca.pem -keystore truststore.jks

//import the temp truststore into cassandra's truststore

keytool -importkeystore -srckeystore truststore.jks -destkeystore truststore.pfx -deststoretype pkcs12 

//import client key and cert 
keytool -importkeystore -destkeystore kmip_keystore.jks -srcstoretype PKCS12 -srckeystore kmip_keystore.p12

copy the trust store and keystore to cassandra

config dse.yaml
kmip_hosts:  
  vault_kmip_group_name:
    hosts: vault.yulei.aws.hashidemos.io
    keystore_path: /etc/dse/conf/kmip_keystore.jks
    keystore_type: jks
    keystore_password: password
    truststore_path: /etc/dse/conf/kmip_truststore.jks
    truststore_type: jks
    truststore_password: password
    key_cache_millis: N
    timeout: N
    protocol: protocol
    cipher_suites: supported_cipher

command line:
dsetool managekmip list vault_kmip_group_name

reference:
https://docs.datastax.com/en/security/6.7/security/secEncryptExternalKeys.html#secEncryptExternalKeys
