#!/bin/bash

# Default values
PROFILE="default"
ALL_PROFILES=false

# Help function
show_help() {
    echo "Usage: $0 [-p <profile_name> | -a]"
    echo ""
    echo "Options:"
    echo "  -p    Clean specific profile (default: 'default')"
    echo "  -a    Clean ALL profiles"
    echo "  -h    Show this help message"
    echo ""
    exit 1
}

# Parse command line arguments
while getopts "p:ah" opt; do
    case $opt in
        p) PROFILE="$OPTARG" ;;
        a) ALL_PROFILES=true ;;
        h) show_help ;;
        \?) echo "❌ Invalid option: -$OPTARG"; show_help ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$ALL_PROFILES" = true ]; then
    echo "⚠️  WARNING: This will delete ALL profiles and certificates in $SCRIPT_DIR."
    echo "   (excluding scripts and master config)"
else
    echo "⚠️  WARNING: This will delete the profile '$PROFILE' in $SCRIPT_DIR/$PROFILE."
fi

read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$ALL_PROFILES" = true ]; then
        # Find directories in certs/ that are not ., .., or special folders if any
        # safely we can just remove subdirectories that look like profiles
        # For safety, let's just look for directories containing 'openssl.cnf' or just standard profile struct
        # Or simpler:
        find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -exec rm -rf {} +
        echo "✅ Cleaned up ALL profiles."
    else
        PROFILE_DIR="$SCRIPT_DIR/$PROFILE"
        if [ -d "$PROFILE_DIR" ]; then
            rm -rf "$PROFILE_DIR"
            echo "✅ Cleaned up profile '$PROFILE'."
        else
            echo "ℹ️  Profile '$PROFILE' does not exist."
        fi
    fi
fi
