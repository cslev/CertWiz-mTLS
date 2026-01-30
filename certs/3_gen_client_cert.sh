#!/bin/bash
set -e

echo "=========================================="
echo "  Client Certificate Generator"
echo "=========================================="
echo ""

# Default values
VALIDITY_DAYS=30
CLIENT_NAME=""
PROFILE=""
ENCRYPT_KEY=true

# Help function
show_help() {
    echo "Usage: $0 -n <client_name> -p <profile_name> [-d <days>] [-u]"
    echo ""
    echo "Options:"
    echo "  -n    Client name (required)"
    echo "  -p    Profile name (REQUIRED)"
    echo "  -d    Certificate validity in days (default: 30)"
    echo "  -u    Unencrypted: Generate key without password and P12 with empty password"
    echo "  -h    Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -n john-doe -p project-alpha -u"
    exit 1
}

# Parse command line arguments using getopts
while getopts "n:p:d:uh" opt; do
    case $opt in
        n) CLIENT_NAME="$OPTARG" ;;
        p) PROFILE="$OPTARG" ;;
        d) VALIDITY_DAYS="$OPTARG" ;;
        u) ENCRYPT_KEY=false ;;
        h) show_help ;;
        \?) echo "❌ Invalid option: -$OPTARG"; show_help ;;
    esac
done

# Validation
if [[ -z "$CLIENT_NAME" ]]; then
    echo "❌ Error: Client name is required!"
    show_help
fi

if [[ -z "$PROFILE" ]]; then
    echo "❌ Error: Profile name is required!"
    show_help
fi

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/$PROFILE"
CA_DIR="$PROFILE_DIR/ca"
CLIENT_DIR="$PROFILE_DIR/client"

echo "🔧 Using Profile: $PROFILE"

# Check if CA exists
if [ ! -f "$CA_DIR/ca.crt" ] || [ ! -f "$CA_DIR/ca.key" ]; then
    echo "❌ Error: CA files not found in profile '$PROFILE'."
    echo "   Please run './1_gen_ca.sh -p $PROFILE' first."
    exit 1
fi

mkdir -p "$CLIENT_DIR"
echo "📁 Output directory: $CLIENT_DIR"
echo "👤 Client name: $CLIENT_NAME"
echo ""

# Switch to profile dir for Openssl config relative paths
cd "$PROFILE_DIR"

# Generate client private key
if [ "$ENCRYPT_KEY" = true ]; then
    echo "🔑 Generating encrypted client private key (2048-bit RSA with AES-256)..."
    openssl genrsa \
      -aes256 \
      -out "client/${CLIENT_NAME}.key" 2048
else
    echo "🔑 Generating UNENCRYPTED client private key (2048-bit RSA)..."
    openssl genrsa \
      -out "client/${CLIENT_NAME}.key" 2048
fi

if [ $? -eq 0 ]; then
    echo "✅ Successfully generated client private key: $CLIENT_DIR/${CLIENT_NAME}.key"
    echo ""
else
    echo "❌ Failed to generate client private key"
    exit 1
fi

# Generate Certificate Signing Request (CSR)
echo "📝 Creating Certificate Signing Request (CSR)..."
SUBJ="/CN=${CLIENT_NAME}"
echo "   - Common Name (CN): ${CLIENT_NAME}"
openssl req \
  -new \
  -key "client/${CLIENT_NAME}.key" \
  -subj "$SUBJ" \
  -out "client/${CLIENT_NAME}.csr"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created CSR: $CLIENT_DIR/${CLIENT_NAME}.csr"
    echo ""
else
    echo "❌ Failed to create CSR"
    exit 1
fi

# Sign the client certificate with CA
echo "✍️  Signing client certificate with CA..."
openssl ca \
  -config openssl.cnf \
  -extensions client_cert \
  -days "$VALIDITY_DAYS" \
  -notext \
  -md sha256 \
  -in "client/${CLIENT_NAME}.csr" \
  -out "client/${CLIENT_NAME}.crt" \
  -batch

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

if [ "$ENCRYPT_KEY" = true ]; then
    openssl pkcs12 \
      -export \
      -out "client/${CLIENT_NAME}.p12" \
      -inkey "client/${CLIENT_NAME}.key" \
      -in "client/${CLIENT_NAME}.crt" \
      -certfile "ca/ca.crt"
else
    # Create P12 with empty export password for full automation support
    openssl pkcs12 \
      -export \
      -out "client/${CLIENT_NAME}.p12" \
      -inkey "client/${CLIENT_NAME}.key" \
      -in "client/${CLIENT_NAME}.crt" \
      -certfile "ca/ca.crt" \
      -passout pass:
fi

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
echo "📦 Generated files for profile '$PROFILE':"
echo "   - Private key: $CLIENT_DIR/${CLIENT_NAME}.key"
echo "   - CSR:         $CLIENT_DIR/${CLIENT_NAME}.csr"
echo "   - Certificate: $CLIENT_DIR/${CLIENT_NAME}.crt"
echo "   - PKCS12:      $CLIENT_DIR/${CLIENT_NAME}.p12"
echo ""

# Display certificate details
echo "📋 Client Certificate Details:"
echo "=========================================="
openssl x509 \
  -in "client/${CLIENT_NAME}.crt" \
  -text \
  -noout

echo ""
echo "=========================================="

