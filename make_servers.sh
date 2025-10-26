#!/bin/bash
# ============================
# Server Certificate Creation Script
# ============================

set -e
source config.sh

CA_DIR="./ca"
HOSTS_FILE="hosts.txt"
OUTPUT_DIR="./servers"

# Check prerequisites
if [ ! -f "$HOSTS_FILE" ]; then
    echo "❌ Error: File $HOSTS_FILE not found."
    exit 1
fi
if [ ! -f "$CA_DIR/ca.crt" ] || [ ! -f "$CA_DIR/ca.key" ]; then
    echo "❌ Error: CA certificate or key not found in $CA_DIR. Run makeca.sh first."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Iterate through each hostname
while IFS= read -r SERVER || [ -n "$SERVER" ]; do
    SERVER=$(echo "$SERVER" | tr -d '\r')
    [ -z "$SERVER" ] && continue  # skip empty lines
    echo "🔹 Creating SSL for $SERVER"

    # Define paths
    KEY_FILE="$OUTPUT_DIR/$SERVER.key"
    CSR_FILE="$OUTPUT_DIR/$SERVER.csr"
    CRT_FILE="$OUTPUT_DIR/$SERVER.crt"
    PFX_FILE="$OUTPUT_DIR/$SERVER.pfx"
    CNF_FILE="$OUTPUT_DIR/openssl_$SERVER.cnf"

    # Generate per-host OpenSSL config with SANs
    cat > "$CNF_FILE" <<EOF
[ req ]
default_bits        = 2048
default_md          = sha256
prompt              = no
distinguished_name  = req_distinguished_name
req_extensions      = v3_req

[ req_distinguished_name ]
C                   = $C
ST                  = $ST
L                   = $L
O                   = $O
OU                  = $OU
CN                  = $SERVER
emailAddress        = $MAIL

[ v3_req ]
basicConstraints    = CA:FALSE
keyUsage            = digitalSignature, keyEncipherment
extendedKeyUsage    = serverAuth, clientAuth
subjectAltName      = @alt_names

[ alt_names ]
DNS.1 = $SERVER
$(echo "$ALT_NAMES" | awk -F'[ ,]+' '{for (i=1;i<=NF;i++) printf "DNS.%d = %s\n", i+1, $i}')
EOF

    echo "   → Generating private key and CSR..."
    openssl req -new -nodes -config "$CNF_FILE" \
        -keyout "$KEY_FILE" -out "$CSR_FILE"

    echo "   → Signing certificate with CA..."
    openssl x509 -req -in "$CSR_FILE" \
        -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
        -out "$CRT_FILE" -days 1825 -sha256 -extensions v3_req \
        -extfile "$CNF_FILE"

    echo "   → Exporting PFX..."
    openssl pkcs12 -export -inkey "$KEY_FILE" -in "$CRT_FILE" \
        -certfile "$CA_DIR/ca.crt" -out "$PFX_FILE" \
        -password pass:$PASSWORD -name "BAEX SSL $SERVER"

    echo "✅ Created: $SERVER (CRT, KEY, CSR, PFX)"
done < "$HOSTS_FILE"

echo "🎉 All server certificates created in $OUTPUT_DIR/"
