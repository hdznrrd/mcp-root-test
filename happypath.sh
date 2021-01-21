#!/bin/bash

. common.sh


step "generate private key"
openssl ecparam -out ca_key.pem -name secp384r1 -genkey
result 

step "generate CA cert"
openssl req -new -key ca_key.pem -x509 -nodes -days 3650 -out ca_cert.pem
result

step "register CA cert in root CA service"
curl -XPOST --data-binary @ca_cert.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/root
result

step "TEST: get roots"
curl http://localhost:8080/api/roots
result

step "TEST: get specific root"
curl http://localhost:8080/api/root/1
result

step "generate attestor key"
openssl ecparam -out attestor_private_key.pem -name secp384r1 -genkey
result

step "generate attestor cert"
openssl req -new -key attestor_private_key.pem -x509 -nodes -days 3650 -out attestor-cert.pem
result

step "TEST: register attestor"
curl -XPOST --data-binary @attestor-cert.pem -H "Content-Type: application/pem-certificate-chain" http://localhost:8080/api/attestor
result

step "TEST: get attestors"
curl http://localhost:8080/api/attestors
result

step "TEST: get specific attestor"
curl http://localhost:8080/api/attestor/1
result

step "creating attestation"
openssl dgst -sha384 -sign attestor_private_key.pem ca_cert.pem | xxd -plain | tr -d "\n" > attestation.sha384 # openssl doesn't output signature as hex by default
result

data='{"attestorId":1,"rootCAid":1,"signature":"'$(cat attestation.sha384)'","algorithmIdentifier":"SHA384WithECDSA"}'
step "TEST: posting attestation: $data"
curl -XPOST -d "$data" -H "Content-Type: application/json" http://localhost:8080/api/attestation
result

step "TEST: get attestations"
curl http://localhost:8080/api/attestations
result

step "TEST: get specific attestation"
curl http://localhost:8080/api/attestation/1
result

step "revoke attestation"
openssl dgst -sha384 -sign attestor_private_key.pem attestation.sha384 | xxd -plain | tr -d "\n" > revocation.sha384 # openssl doesn't output signature as hex by default
result

data='{"attestorId":1,"rootCAid":1,"attestationId":1,"signature":"'$(cat revocation.sha384)'","algorithmIdentifier":"SHA384WithECDSA"}'
step "TEST: revoking attestation: $data"
curl -XPOST -d "$data" -H "Content-Type: application/json" http://localhost:8080/api/revocation
result

step "TEST: get all revocations"
curl http://localhost:8080/api/revocations
result

step "TEST: get specific revocation"
curl http://localhost:8080/api/revocation/1
result



