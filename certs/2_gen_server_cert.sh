#!/bin/bash
set -e

echo "=========================================="
echo "  Server Certificate Generator"
echo "=========================================="
echo ""

# Default values
PROFILE=""
SERVER_NAME="localhost"
VALIDITY_DAYS=365

# Help function
show_help() {
    echo "Usage: $0 -p <profile_name> [-n <server_name>] [-d <days>]"
    echo ""
    echo "Options:"
    echo "  -p    Profile name (REQUIRED)"
    echo "  -n    Server Common Name (CN) (default: 'localhost')"
    echo "  -d    Certificate validity in days (default: 365)"
    echo "  -h    Show this help message"
    echo ""
    exit 1
}

# Parse command line arguments
while getopts "p:n:d:h" opt; do
    case $opt in
        p) PROFILE="$OPTARG" ;;
        n) SERVER_NAME="$OPTARG" ;;
        d) VALIDITY_DAYS="$OPTARG" ;;
        h) show_help ;;
        \?) echo "❌ Invalid option: -$OPTARG"; show_help ;;
    esac
done

if [ -z "$PROFILE" ]; then
    echo "❌ Error: Profile name is required."
    show_help
fi

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/$PROFILE"
CA_DIR="$PROFILE_DIR/ca"
SERVER_DIR="$PROFILE_DIR/server"

echo "🔧 Using Profile: $PROFILE"
echo "🔧 Server Name:   $SERVER_NAME"

# Check if CA exists
if [ ! -f "$CA_DIR/ca.crt" ] || [ ! -f "$CA_DIR/ca.key" ]; then
    echo "❌ Error: CA files not found in profile '$PROFILE'."
    echo "   Please run './1_gen_ca.sh -p $PROFILE' first."
    exit 1
fi

mkdir -p "$SERVER_DIR"
echo "📁 Output directory: $SERVER_DIR"
echo ""

# Switch to profile dir for Openssl config relative paths
cd "$PROFILE_DIR"

# Generate server private key
echo "🔑 Generating server private key (2048-bit RSA)..."
openssl genrsa \
  -out "server/${SERVER_NAME}.key" 2048

if [ $? -eq 0 ]; then
    echo "✅ Successfully generated server private key: $SERVER_DIR/${SERVER_NAME}.key"
    echo ""
else
    echo "❌ Failed to generate server private key"
    exit 1
fi

# Generate Certificate Signing Request (CSR)
echo "📝 Creating Certificate Signing Request (CSR)..."
echo "   - Common Name (CN): $SERVER_NAME"
openssl req \
  -new \
  -key "server/${SERVER_NAME}.key" \
  -subj "/CN=$SERVER_NAME" \
  -out "server/${SERVER_NAME}.csr"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created CSR: $SERVER_DIR/${SERVER_NAME}.csr"
    echo ""
else
    echo "❌ Failed to create CSR"
    exit 1
fi

# Sign the server certificate with CA
echo "✍️  Signing server certificate with CA..."
openssl ca \
  -config openssl.cnf \
  -extensions server_cert \
  -days "$VALIDITY_DAYS" \
  -notext \
  -md sha256 \
  -in "server/${SERVER_NAME}.csr" \
  -out "server/${SERVER_NAME}.crt" \
  -batch

if [ $? -eq 0 ]; then
    echo "✅ Successfully signed server certificate: $SERVER_DIR/${SERVER_NAME}.crt"
    echo ""
else
    echo "❌ Failed to sign server certificate"
    exit 1
fi

echo "=========================================="
echo "✅ Server certificate generation complete!"
echo "=========================================="
echo ""
echo "📦 Generated files for profile '$PROFILE':"
echo "   - Private key: $SERVER_DIR/${SERVER_NAME}.key"
echo "   - CSR:         $SERVER_DIR/${SERVER_NAME}.csr"
echo "   - Certificate: $SERVER_DIR/${SERVER_NAME}.crt"
echo ""

# Display certificate details
echo "📋 Server Certificate Details:"
echo "=========================================="
openssl x509 \
  -in "server/${SERVER_NAME}.crt" \
  -text \
  -noout

echo ""
echo "=========================================="

