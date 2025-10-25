#!/bin/bash
# ============================
# CA Certificate Creation Script
# ============================

set -e
source config.sh

# Generate OpenSSL config dynamically using template
cat > openssl_ca.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./ca
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
private_key       = \$dir/ca.key
certificate       = \$dir/ca.crt
default_md        = sha256
policy            = policy_anything
x509_extensions   = v3_ca

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
default_md          = sha256
prompt              = no
distinguished_name  = req_distinguished_name
x509_extensions     = v3_ca

[ req_distinguished_name ]
C                   = $C
ST                  = $ST
L                   = $L
O                   = $O
OU                  = $OU
CN                  = $CN
emailAddress        = $MAIL

[ v3_ca ]
basicConstraints    = critical, CA:TRUE
keyUsage            = critical, keyCertSign, cRLSign
subjectKeyIdentifier= hash
authorityKeyIdentifier= keyid:always,issuer
extendedKeyUsage    = serverAuth, clientAuth
subjectAltName      = @alt_names

[ alt_names ]
$(echo "$ALT_NAMES" | awk -F'[ ,]+' '{for (i=1;i<=NF;i++) printf "DNS.%d = %s\n", i, $i}')
EOF

# Prepare CA directories
mkdir -p ca/{certs,crl,newcerts}
touch ca/index.txt
echo 1000 > ca/serial

# Generate CA key and self-signed certificate
openssl req -x509 -newkey rsa:2048 -days $DAYS -nodes \
    -keyout ca/ca.key -out ca/ca.crt \
    -config openssl_ca.cnf -extensions v3_ca

# Create CSR for reference
openssl req -new -key ca/ca.key -out ca/ca.csr -config openssl_ca.cnf

# Export PFX with friendly name
openssl pkcs12 -export -inkey ca/ca.key -in ca/ca.crt \
    -out ca/ca.pfx -password pass:$PASSWORD \
    -name "$FRIENDLY_NAME"

echo "✅ CA certificate, key, CSR, and PFX created in ./ca/"
