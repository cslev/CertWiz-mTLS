#!/bin/bash
set -e

echo "=========================================="
echo "  Server Certificate Generator"
echo "=========================================="
echo ""

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/ca"
SERVER_DIR="$SCRIPT_DIR/server"
mkdir -p "$SERVER_DIR"

echo "📁 Output directory: $SERVER_DIR"
echo "📁 CA directory: $CA_DIR"
echo ""

# Check if CA files exist
if [ ! -f "$CA_DIR/ca.crt" ] || [ ! -f "$CA_DIR/ca.key" ]; then
    echo "❌ Error: CA certificate or key not found!"
    echo "   Please run 1_gen_ca.sh first to generate the CA."
    exit 1
fi

# Generate server private key
echo "🔑 Generating server private key (2048-bit RSA)..."
openssl genrsa \
  -out "$SERVER_DIR/server.key" 2048

if [ $? -eq 0 ]; then
    echo "✅ Successfully generated server private key: $SERVER_DIR/server.key"
    echo ""
else
    echo "❌ Failed to generate server private key"
    exit 1
fi

# Generate Certificate Signing Request (CSR)
echo "📝 Creating Certificate Signing Request (CSR)..."
echo "   - Common Name (CN): localhost"
openssl req \
  -new \
  -key "$SERVER_DIR/server.key" \
  -subj '/CN=localhost' \
  -out "$SERVER_DIR/server.csr"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created CSR: $SERVER_DIR/server.csr"
    echo ""
else
    echo "❌ Failed to create CSR"
    exit 1
fi

# Sign the server certificate with CA
echo "✍️  Signing server certificate with CA..."
echo "   - Validity: 365 days"
openssl x509 \
  -req \
  -in "$SERVER_DIR/server.csr" \
  -CA "$CA_DIR/ca.crt" \
  -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial \
  -days 365 \
  -out "$SERVER_DIR/server.crt"

if [ $? -eq 0 ]; then
    echo "✅ Successfully signed server certificate: $SERVER_DIR/server.crt"
    echo ""
else
    echo "❌ Failed to sign server certificate"
    exit 1
fi

echo "=========================================="
echo "✅ Server certificate generation complete!"
echo "=========================================="
echo ""
echo "📦 Generated files:"
echo "   - Private key: $SERVER_DIR/server.key"
echo "   - CSR:         $SERVER_DIR/server.csr"
echo "   - Certificate: $SERVER_DIR/server.crt"
echo ""

# Display certificate details
echo "📋 Server Certificate Details:"
echo "=========================================="
openssl x509 \
  -in "$SERVER_DIR/server.crt" \
  -text \
  -noout

echo ""
echo "=========================================="

