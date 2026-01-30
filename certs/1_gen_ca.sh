#!/bin/bash
set -e

echo "=========================================="
echo "  Certificate Authority (CA) Generator"
echo "=========================================="
echo ""

# Default values
PROFILE=""

# Help function
show_help() {
    echo "Usage: $0 -p <profile_name>"
    echo ""
    echo "Options:"
    echo "  -p    Profile name (REQUIRED)"
    echo "  -h    Show this help message"
    echo ""
    exit 1
}

# Parse command line arguments
while getopts "p:h" opt; do
    case $opt in
        p) PROFILE="$OPTARG" ;;
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
DB_DIR="$PROFILE_DIR/db"

echo "🔧 Using Profile: $PROFILE"
echo "📁 Profile Directory: $PROFILE_DIR"

mkdir -p "$CA_DIR"
mkdir -p "$DB_DIR/certs" "$DB_DIR/newcerts" "$DB_DIR/crl" "$DB_DIR/private"
chmod 700 "$DB_DIR/private"

# Copy openssl config if not present
if [ ! -f "$PROFILE_DIR/openssl.cnf" ]; then
    if [ -f "$SCRIPT_DIR/openssl.cnf" ]; then
        cp "$SCRIPT_DIR/openssl.cnf" "$PROFILE_DIR/openssl.cnf"
        echo "📄 Copied openssl.cnf template to profile."
    else
        echo "❌ Error: Master openssl.cnf not found in $SCRIPT_DIR"
        exit 1
    fi
fi

# Switch to profile dir so openssl.cnf relative paths work
cd "$PROFILE_DIR"

echo "⚙️  Initializing CA Database..."

# Initialize CA Database files
if [ ! -f "db/index.txt" ]; then
    touch "db/index.txt"
    echo "   - Created index.txt"
fi
if [ ! -f "db/serial" ]; then
    echo "1000" > "db/serial"
    echo "   - Initialized serial number"
fi
if [ ! -f "db/crlnumber" ]; then
     echo "1000" > "db/crlnumber"
     echo "   - Initialized CRL number"
fi
echo ""

echo "🔐 Generating CA private key and self-signed certificate..."
echo "   - Certificate will be valid for 365 days"
echo "   - Common Name (CN): my-ca-$PROFILE"
echo ""

openssl req \
  -new \
  -x509 \
  -nodes \
  -days 365 \
  -subj "/CN=my-ca-$PROFILE" \
  -keyout "ca/ca.key" \
  -out "ca/ca.crt"

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
  -in "ca/ca.crt" \
  -text \
  --noout

echo ""
echo "=========================================="
echo "✅ CA generation complete!"
echo "=========================================="
