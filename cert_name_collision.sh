#!/bin/bash

. common.sh


step "generate private keys"
openssl ecparam -out ca_key_1.pem -name secp384r1 -genkey
result
openssl ecparam -out ca_key_2.pem -name secp384r1 -genkey
result 


step "generate CA certs"
openssl req -new -key ca_key_1.pem -x509 -nodes -days 3650 -out ca_cert_1.pem -subj "/C=DE/ST=state/L=locality/O=company/OU=orgunit/CN=root"
result
openssl req -new -key ca_key_2.pem -x509 -nodes -days 3650 -out ca_cert_2.pem -subj "/C=DE/ST=state/L=locality/O=company/OU=orgunit/CN=root"
result

step "register CA certs in root CA service"
curl -XPOST --data-binary @ca_cert_1.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/root
result
curl -XPOST --data-binary @ca_cert_2.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/root
result

step "TEST: get roots"
curl http://localhost:8080/api/roots
result

step "TEST: get specific root"
curl http://localhost:8080/api/root/1
result
curl http://localhost:8080/api/root/2
result

