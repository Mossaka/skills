#!/bin/bash
# Cleanup (revoke) a GitHub Personal Access Token
# Usage: ./cleanup-token.sh [token-file]

set -e

TOKEN_FILE="${1:-$HOME/.github-readonly-token}"
METADATA_FILE="${TOKEN_FILE}.metadata"

echo "Cleaning up GitHub token..."
echo ""

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found: $TOKEN_FILE"
    exit 1
fi

if [ ! -f "$METADATA_FILE" ]; then
    echo "Warning: Metadata file not found: $METADATA_FILE"
    echo "Will delete local token file but cannot revoke from GitHub."
    read -p "Continue? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        exit 1
    fi
    rm -f "$TOKEN_FILE"
    echo "✅ Local token file deleted"
    exit 0
fi

# Load metadata
source "$METADATA_FILE"

echo "Token details:"
echo "  Name: $TOKEN_NAME"
echo "  ID: $TOKEN_ID"
echo "  Created: $CREATED_AT"
echo "  File: $OUTPUT_FILE"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Warning: gh CLI is not installed. Cannot revoke token from GitHub."
    echo "Will only delete local files."
    read -p "Continue? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        exit 1
    fi
    rm -f "$TOKEN_FILE" "$METADATA_FILE"
    echo "✅ Local token files deleted"
    exit 0
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Warning: Not authenticated with gh CLI. Cannot revoke token from GitHub."
    echo "Will only delete local files."
    read -p "Continue? [y/N]: " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        exit 1
    fi
    rm -f "$TOKEN_FILE" "$METADATA_FILE"
    echo "✅ Local token files deleted"
    exit 0
fi

# Revoke the token
if [ -n "$TOKEN_ID" ] && [ "$TOKEN_ID" != "null" ] && [ "$TOKEN_ID" != "" ]; then
    echo "Revoking token from GitHub..."

    # Try to revoke the fine-grained token
    if gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        "/user/tokens/$TOKEN_ID" 2>/dev/null; then
        echo "✅ Token revoked from GitHub"
    else
        echo "⚠️  Could not revoke token from GitHub (may be already revoked or expired)"
    fi
else
    echo "⚠️  No token ID found. This may be a classic token."
    echo "Classic tokens cannot be revoked via API."
    echo "To revoke manually, visit: https://github.com/settings/tokens"
    echo "Look for token: $TOKEN_NAME"
fi

# Delete local files
rm -f "$TOKEN_FILE" "$METADATA_FILE"
echo "✅ Local token files deleted"
echo ""
echo "Cleanup complete!"
