#!/bin/bash
set -e

echo "=========================================="
echo "  Certificate Authority (CA) Generator"
echo "=========================================="
echo ""

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/ca"
mkdir -p "$CA_DIR"

echo "📁 Output directory: $CA_DIR"
echo ""

# Generate CA certificate and private key
echo "🔐 Generating CA private key and self-signed certificate..."
echo "   - Certificate will be valid for 365 days"
echo "   - Common Name (CN): my-ca"
echo ""

openssl req \
  -new \
  -x509 \
  -nodes \
  -days 365 \
  -subj '/CN=my-ca' \
  -keyout "$CA_DIR/ca.key" \
  -out "$CA_DIR/ca.crt"

if [ $? -eq 0 ]; then
    echo "✅ Successfully generated CA certificate and key:"
    echo "   - Private key: $CA_DIR/ca.key"
    echo "   - Certificate: $CA_DIR/ca.crt"
    echo ""
else
    echo "❌ Failed to generate CA certificate"
    exit 1
fi

# Display certificate details
echo "📋 Certificate Details:"
echo "=========================================="
openssl x509 \
  --in "$CA_DIR/ca.crt" \
  -text \
  --noout

echo ""
echo "=========================================="
echo "✅ CA generation complete!"
echo "=========================================="
