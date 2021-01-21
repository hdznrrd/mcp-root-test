#!/bin/bash

# script didn't work with /bin/sh in Ubuntu on WSL2 

function delay () {
  read -n 1 -s
}

rm -f *pem *sha384



echo "generate private key"
delay
openssl ecparam -out ca_key.pem -name secp384r1 -genkey

echo "generate CA cert"
delay
openssl req -new -key ca_key.pem -x509 -nodes -days 3650 -out ca_cert.pem

echo "register CA cert in root CA service"
delay
curl -XPOST --data-binary @ca_cert.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/root

echo "TEST: get roots"
delay
curl http://localhost:8080/api/roots

echo "TEST: get specific root"
delay
curl http://localhost:8080/api/root/1

echo "generate attestor key"
delay
openssl ecparam -out attestor_private_key.pem -name secp384r1 -genkey

echo "generate attestor cert"
delay
openssl req -new -key attestor_private_key.pem -x509 -nodes -days 3650 -out attestor-cert.pem

echo "TEST: register attestor"
delay
curl -XPOST --data-binary @attestor-cert.pem -H "Content-Type: application/pem-certificate-chain" http://localhost:8080/api/attestor

echo "TEST: get attestors"
delay
curl http://localhost:8080/api/attestors

echo "TEST: get specific attestor"
delay
curl http://localhost:8080/api/attestor/1

echo "creating attestation"
delay
openssl dgst -sha384 -sign attestor_private_key.pem ca_cert.pem | xxd -plain | tr -d "\n" > attestation.sha384 # openssl doesn't output signature as hex by default

data='{"attestorId":1,"rootCAid":1,"signature":"'$(cat attestation.sha384)'","algorithmIdentifier":"SHA384WithECDSA"}'
echo "TEST: posting attestation: $data"
delay
curl -XPOST -d "$data" -H "Content-Type: application/json" http://localhost:8080/api/attestation

echo "TEST: get attestations"
delay
curl http://localhost:8080/api/attestations

echo "TEST: get specific attestation"
delay
curl http://localhost:8080/api/attestation/1

echo "revoke attestation"
delay
openssl dgst -sha384 -sign attestor_private_key.pem attestation.sha384 | xxd -plain | tr -d "\n" > revocation.sha384 # openssl doesn't output signature as hex by default

data='{"attestorId":1,"rootCAid":1,"attestationId":1,"signature":"'$(cat revocation.sha384)'","algorithmIdentifier":"SHA384WithECDSA"}'
echo "TEST: revoking attesation: $data"
delay
curl -XPOST -d "$data" -H "Content-Type: application/json" http://localhost:8080/api/revocation

echo "TEST: get all revocations"
delay
curl http://localhost:8080/api/revocations

echo "TEST: get specific revocation"
delay
curl http://localhost:8080/api/revocation/1


