#!/bin/bash
set -e

echo "=========================================="
echo "  Client Certificate Generator"
echo "=========================================="
echo ""

# Parse client name argument
CLIENT_NAME=$1

if [[ -z $CLIENT_NAME ]]; then
  echo "❌ Error: No client name specified!"
  echo ""
  echo "Usage: $0 <client_name>"
  echo "Example: $0 john-doe"
  echo ""
  exit 1
fi

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/ca"
CLIENT_DIR="$SCRIPT_DIR/client"
mkdir -p "$CLIENT_DIR"

echo "📁 Output directory: $CLIENT_DIR"
echo "📁 CA directory: $CA_DIR"
echo "👤 Client name: $CLIENT_NAME"
echo ""

# Check if CA files exist
if [ ! -f "$CA_DIR/ca.crt" ] || [ ! -f "$CA_DIR/ca.key" ]; then
    echo "❌ Error: CA certificate or key not found!"
    echo "   Please run 1_gen_ca.sh first to generate the CA."
    exit 1
fi

# Generate client private key (with AES-256 encryption)
echo "🔑 Generating encrypted client private key (2048-bit RSA with AES-256)..."
openssl genrsa \
  -aes256 \
  -out "$CLIENT_DIR/${CLIENT_NAME}.key" 2048

if [ $? -eq 0 ]; then
    echo "✅ Successfully generated client private key: $CLIENT_DIR/${CLIENT_NAME}.key"
    echo ""
else
    echo "❌ Failed to generate client private key"
    exit 1
fi

# Generate Certificate Signing Request (CSR)
echo "📝 Creating Certificate Signing Request (CSR)..."
SUBJ="/CN=client-${CLIENT_NAME}"
echo "   - Common Name (CN): client-${CLIENT_NAME}"
openssl req \
  -new \
  -key "$CLIENT_DIR/${CLIENT_NAME}.key" \
  -subj "$SUBJ" \
  -out "$CLIENT_DIR/${CLIENT_NAME}.csr"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created CSR: $CLIENT_DIR/${CLIENT_NAME}.csr"
    echo ""
else
    echo "❌ Failed to create CSR"
    exit 1
fi

# Sign the client certificate with CA
echo "✍️  Signing client certificate with CA..."
echo "   - Validity: 1095 days (3 years)"
openssl x509 \
  -req \
  -in "$CLIENT_DIR/${CLIENT_NAME}.csr" \
  -CA "$CA_DIR/ca.crt" \
  -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial \
  -days 1095 \
  -out "$CLIENT_DIR/${CLIENT_NAME}.crt"

if [ $? -eq 0 ]; then
    echo "✅ Successfully signed client certificate: $CLIENT_DIR/${CLIENT_NAME}.crt"
    echo ""
else
    echo "❌ Failed to sign client certificate"
    exit 1
fi

# Create PKCS12 bundle (.p12 file)
echo "📦 Creating PKCS12 bundle (.p12 file)..."
echo "   - Including: client certificate, client key, and CA certificate"
openssl pkcs12 \
  -export \
  -out "$CLIENT_DIR/${CLIENT_NAME}.p12" \
  -inkey "$CLIENT_DIR/${CLIENT_NAME}.key" \
  -in "$CLIENT_DIR/${CLIENT_NAME}.crt" \
  -certfile "$CA_DIR/ca.crt"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created PKCS12 bundle: $CLIENT_DIR/${CLIENT_NAME}.p12"
    echo ""
else
    echo "❌ Failed to create PKCS12 bundle"
    exit 1
fi

echo "=========================================="
echo "✅ Client certificate generation complete!"
echo "=========================================="
echo ""
echo "📦 Generated files:"
echo "   - Private key: $CLIENT_DIR/${CLIENT_NAME}.key"
echo "   - CSR:         $CLIENT_DIR/${CLIENT_NAME}.csr"
echo "   - Certificate: $CLIENT_DIR/${CLIENT_NAME}.crt"
echo "   - PKCS12:      $CLIENT_DIR/${CLIENT_NAME}.p12"
echo ""

# Display certificate details
echo "📋 Client Certificate Details:"
echo "=========================================="
openssl x509 \
  -in "$CLIENT_DIR/${CLIENT_NAME}.crt" \
  -text \
  -noout

echo ""
echo "=========================================="

