#!/bin/bash
set -e

echo "=========================================="
echo "  Client Certificate Revocation"
echo "=========================================="
echo ""

# Default values
CLIENT_NAME=""

# Help function
show_help() {
    echo "Usage: $0 -n <client_name>"
    echo ""
    echo "Options:"
    echo "  -n    Client name to revoke (required)"
    echo "  -h    Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -n john-doe"
    exit 1
}

# Parse command line arguments using getopts
while getopts "n:h" opt; do
    case $opt in
        n) CLIENT_NAME="$OPTARG" ;;
        h) show_help ;;
        \?) echo "❌ Invalid option: -$OPTARG"; show_help ;;
    esac
done

# Validation
if [[ -z "$CLIENT_NAME" ]]; then
    echo "❌ Error: Client name is required!"
    show_help
fi

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/ca"
CLIENT_DIR="$SCRIPT_DIR/client"
DB_DIR="$SCRIPT_DIR/db"
CONFIG_FILE="$SCRIPT_DIR/openssl-crl.cnf"
CRL_FILE="$SCRIPT_DIR/crl.pem"

# Ensure we are in the script directory for relative config paths
cd "$SCRIPT_DIR"

echo "📂 Working directory: $SCRIPT_DIR"
echo "👤 Revoking client: $CLIENT_NAME"

# Check if client certificate exists
CRT_FILE="$CLIENT_DIR/${CLIENT_NAME}.crt"
if [ ! -f "$CRT_FILE" ]; then
    echo "❌ Error: Client certificate not found at $CRT_FILE"
    exit 1
fi

# --- Initialize CA Database (if needed) ---
mkdir -p "$DB_DIR/certs" "$DB_DIR/newcerts" "$DB_DIR/crl"
mkdir -p "$DB_DIR/private"
chmod 700 "$DB_DIR/private"

# Create index.txt if it doesn't exist
if [ ! -f "$DB_DIR/index.txt" ]; then
    echo "⚙️  Initializing CA database (index.txt)..."
    touch "$DB_DIR/index.txt"
fi

# Create crlnumber if it doesn't exist
if [ ! -f "$DB_DIR/crlnumber" ]; then
    echo "⚙️  Initializing CRL number..."
    echo "1000" > "$DB_DIR/crlnumber"
fi

# --- Import Certificate to Database (if missing) ---
# Since we generated certs with 'openssl x509', they aren't in the database.
# We must manually add the entry to allow revocation.

# Get Certificate Details
# Serial (hex)
SERIAL=$(openssl x509 -in "$CRT_FILE" -serial -noout | cut -d= -f2)
# Subject (RFC2253 format -> legacy OpenSSL DB format /type=value)
# We convert "CN=name,O=org" to "/CN=name/O=org"
SUBJECT=$(openssl x509 -in "$CRT_FILE" -subject -noout -nameopt RFC2253 | sed 's/^subject=//' | sed 's/,/\//g' | sed 's/^/\//')
# End Date
ENDDATE_RAW=$(openssl x509 -in "$CRT_FILE" -enddate -noout | cut -d= -f2)
# Convert Date to YYMMDDHHMMSSZ (using GNU date)
# Note: openssl outputs "Jan 29 12:34:56 2027 GMT"
ENDDATE_Z=$(date -d "$ENDDATE_RAW" +%y%m%d%H%M%SZ)

echo "🔍 Certificate Serial: $SERIAL"

# Check if already revoked or in index
if grep -q "$SERIAL" "$DB_DIR/index.txt"; then
    echo "ℹ️  Certificate already in database."
else
    echo "📝 Importing certificate to CA database..."
    # Format: Status(V) Expiry RevocationDate(empty) Serial File(unknown) Subject
    echo -e "V\t${ENDDATE_Z}\t\t${SERIAL}\tunknown\t${SUBJECT}" >> "$DB_DIR/index.txt"
fi

# --- Revoke Certificate ---
echo "🚫 Revoking certificate..."
openssl ca \
  -config "$CONFIG_FILE" \
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
  -config "$CONFIG_FILE" \
  -gencrl \
  -out "$CRL_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Revocation Complete!"
    echo "=========================================="
    echo "📦 Generated CRL: $CRL_FILE"
    echo ""
    echo "👉 To apply this to NGINX:"
    echo "   1. Copy '$CRL_FILE' to your NGINX SSL directory."
    echo "   2. Configure NGINX:"
    echo "      ssl_crl /path/to/crl.pem;"
    echo "      ssl_verify_client on;"
    echo "   3. Reload NGINX."
    echo ""
else
    echo "❌ Failed to generate CRL."
    exit 1
fi
