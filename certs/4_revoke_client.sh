#!/bin/bash
set -e

echo "=========================================="
echo "  Client Certificate Revocation"
echo "=========================================="
echo ""

# Default values
CLIENT_NAME=""
PROFILE=""

# Help function
show_help() {
    echo "Usage: $0 -n <client_name> -p <profile_name>"
    echo ""
    echo "Options:"
    echo "  -n    Client name to revoke (required)"
    echo "  -p    Profile name (REQUIRED)"
    echo "  -h    Show this help message"
    echo ""
    exit 1
}

# Parse command line arguments using getopts
while getopts "n:p:h" opt; do
    case $opt in
        n) CLIENT_NAME="$OPTARG" ;;
        p) PROFILE="$OPTARG" ;;
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
CRL_FILE="$PROFILE_DIR/crl.pem"

echo "🔧 Using Profile: $PROFILE"

# Check if CA exists
if [ ! -f "$CA_DIR/ca.crt" ]; then
    echo "❌ Error: CA files not found in profile '$PROFILE'."
    exit 1
fi

# Switch to profile dir for Openssl config relative paths
cd "$PROFILE_DIR"

echo "📂 Working directory: $PROFILE_DIR"
echo "👤 Revoking client: $CLIENT_NAME"

# Check if client certificate exists
CRT_FILE="client/${CLIENT_NAME}.crt"
if [ ! -f "$CRT_FILE" ]; then
    echo "❌ Error: Client certificate not found at $PROFILE_DIR/$CRT_FILE"
    exit 1
fi

# --- Revoke Certificate ---
echo "🚫 Revoking certificate..."
openssl ca \
  -config openssl.cnf \
  -revoke "$CRT_FILE" \
  -batch

if [ $? -eq 0 ]; then
    echo "✅ Certificate revoked successfully."
else
    echo "❌ Failed to revoke certificate."
    exit 1
fi

# --- Generate CRL ---
echo "📜 Generating Certificate Revocation List (CRL)..."
openssl ca \
  -config openssl.cnf \
  -gencrl \
  -out "crl.pem"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Revocation Complete!"
    echo "=========================================="
    echo "📦 Generated CRL: $CRL_FILE"
    echo ""
else
    echo "❌ Failed to generate CRL."
    exit 1
fi
