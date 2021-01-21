# Test cases for root CA list service

## Prerequisites

* Get the root CA list service up and running (<https://github.com/oliverhaagh/MCP-Root>)
  * Remember to change the active profile from 'test' to 'prod' in <https://github.com/oliverhaagh/MCP-Root/blob/master/src/main/resources/application.yaml>
* OpenSSL
* A rest client (cURL, Postman, etc.)
  * <https://github.com/oliverhaagh/MCP-Root-Client-Python> can alternatively also be used, just remember to change the 'url' variable on line 56 if testing against localhost

## Test case: Get Swagger file

When the application is running the Swagger file can be gotten at <http://localhost:8080/v2/api-docs> and the corresponding OpenAPI 3 file can be gotten at <http://localhost:8080/v3/api-docs>.

## Test case: Create and register new root CA

Create EC private key for CA:

```bash
openssl ecparam -out ca_key.pem -name secp384r1 -genkey
```

Generate the CA certificate:

```bash
openssl req -new -key ca_key.pem -x509 -nodes -days 3650 -out ca_cert.pem
```

Register CA certificate in root CA service:

```bash
curl -XPOST --data-binary @ca_cert.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/root
```

As result a JSON object containing information about and the certificate itself.

## Test case: Get the list of all registered root CAs

```bash
curl http://localhost:8080/api/roots
```

Should return a JSON list containing all registered all root CAs.

## Test case: Get a specific root CA

All registered root CAs have a unique id which is included in the responses of the previous tests. This id can be used to get only the information about a specific root CA.

```bash
curl http://localhost:8080/api/root/1
```

Should return the first root CA that was registered.

## Test case: Register an attestor

For this another certificate must be used, this can either also be self signed or be part of a longer trust chain. For the latter case the certificates of the issuing CAs can optionally be appended in the PEM file of the attetstor being registered as that will result in the root CA service verifying the entire trust chain of the attestor.
To register the attestor:

```bash
curl -XPOST --data-binary @attestor-cert.pem -H "Content-Type: application/x-pem-file" http://localhost:8080/api/attestor
```

Should return a JSON object with information about the attestor, similar to the result of registering a root CA.

## Test case: Get the list of all registered attestors

```bash
curl http://localhost:8080/api/attestors
```

Should return the list of all registered attestors.

## Test case: Get a specific attestor

```bash
curl http://localhost:8080/api/attestor/1
```

Should return the first attestor that was registered.

## Test case: Attest a specific root CA

Attesting a root CA requires signing the PEM encoded certificate of the root CA with the private key of the attestor.

```bash
openssl dgst -sha384 -sign attestor_private_key.key -out attestation.sha384 ca_cert.pem
```

This generates the signature file attestation.sha384. For the actual registration a JSON object needs to be made. Assuming that attestor 1 is attesting root CA 1 and that the attestor used an EC keypair this could like this:

```json
{
    "attestorId": 1,
    "rootCAid": 1,
    "signature" : "<hex encoding of the content of attestation.sha384>",
    "algorithmIdentifier": "SHA384WithECDSA"
}
```

This can then using cURL be posted as such:

```bash
curl -XPOST -d '{"attestorId": 1, ..... }' -H "Content-Type: application/json" http://localhost:8080/api/attestation
```

This can also be done using the Python based client that is linked above:

```bash
python main.py -catt 1 1 attestation.sha384 SHA384WithECDSA
```

The result of either of these should be a JSON object containing the information of the created attestation.

## Test case: Get the list of all attestations

```bash
curl http://localhost:8080/api/attestations
```

Should return the list of all registered attestations.

## Test case: Get a specific attestation

```bash
curl http://localhost:8080/api/attestation/1
```

Should return the first attestation that was registered.

## Test case: Revoke an attestation

Revoking an attestation can only be done by the attestor private key that originally made the attestation and is done by signing the signature of the original attestation.

```bash
openssl dgst -sha384 -sign attestor_private_key.key -out revocation.sha384 attestation.sha384
```

This generates the signature file revocation.sha384. For the actual revocation a JSON object needs to be made. Assuming that attestor 1 is revoking attestation 1 that was made on root CA 1 this could look like this:

```json
{
    "attestorId": 1,
    "rootCAid": 1,
    "attestationId": 1,
    "signature": "<hex encoding of the content of revocation.sha384>",
    "algorithmIdentifier": "SHA384WithECDSA"
}
```

Using cURL this can then be posted as such:

```bash
curl -XPOST -d '{"attestorId": 1, ...}' -H "Content-Type: application/json" http://localhost:8080/api/revocation
```

Alternatively the Python client can be used as such:

```bash
python main.py -cre 1 1 1 revocation.sha384 SHA384WithECDSA
```

Either of these should return a JSON object with information about the revocation.

## Test case: Get the list of all revocations

```bash
curl http://localhost:8080/api/revocations
```

Should return the list of all registered revocations.

## Test case: Get a specific revocation

```bash
curl http://localhost:8080/api/revocation/1
```

Should return the first revocation that was first registered.

## Future considerations

* Signing of a root CA certificate by an attestor is sensitive to different encodings of character sets and line breaks
  * Should the signing be done on the binary encoded version of the CA certificate instead of the PEM encoded version of it?
