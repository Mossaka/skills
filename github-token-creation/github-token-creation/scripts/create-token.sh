#!/bin/bash
# Create a read-only GitHub Personal Access Token
# Usage: ./create-token.sh [token-name] [output-file]

set -e

TOKEN_NAME="${1:-readonly-pat-$(date +%Y%m%d-%H%M%S)}"
OUTPUT_FILE="${2:-$HOME/.github-readonly-token}"
METADATA_FILE="${OUTPUT_FILE}.metadata"

echo "Creating read-only GitHub token: $TOKEN_NAME"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed. Install it from https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with gh CLI. Run 'gh auth login' first."
    exit 1
fi

echo "Select token type:"
echo "1) Fine-grained token (recommended, more secure, repo-specific)"
echo "2) Classic token (legacy, simpler permissions)"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo ""
        echo "Creating fine-grained read-only token..."
        echo ""

        # Get list of repositories the user has access to
        echo "Available repositories:"
        gh repo list --limit 10 --json nameWithOwner --jq '.[].nameWithOwner'
        echo ""

        read -p "Enter repository (format: owner/repo, or leave empty for all accessible repos): " repo

        # Create fine-grained token with read-only permissions
        if [ -z "$repo" ]; then
            # Token for all repositories
            gh api \
              --method POST \
              -H "Accept: application/vnd.github+json" \
              /user/tokens \
              -f name="$TOKEN_NAME" \
              -f description="Read-only access token (auto-generated)" \
              -f permissions[contents]=read \
              -f permissions[metadata]=read \
              -f permissions[pull_requests]=read \
              -f permissions[issues]=read \
              > /tmp/token_response.json
        else
            # Token for specific repository
            gh api \
              --method POST \
              -H "Accept: application/vnd.github+json" \
              /user/tokens \
              -f name="$TOKEN_NAME" \
              -f description="Read-only access token for $repo" \
              -F repositories[]="$repo" \
              -f permissions[contents]=read \
              -f permissions[metadata]=read \
              -f permissions[pull_requests]=read \
              -f permissions[issues]=read \
              > /tmp/token_response.json
        fi

        TOKEN=$(jq -r '.token' /tmp/token_response.json)
        TOKEN_ID=$(jq -r '.id' /tmp/token_response.json)
        ;;
    2)
        echo ""
        echo "Creating classic read-only token..."
        echo "Note: Classic tokens are being deprecated. Consider using fine-grained tokens."
        echo ""

        # For classic tokens, use the web UI as the API requires basic auth
        echo "Opening GitHub token creation page..."
        gh browse --settings tokens
        echo ""
        echo "Please:"
        echo "1. Click 'Generate new token (classic)'"
        echo "2. Set name: $TOKEN_NAME"
        echo "3. Select scopes: public_repo, read:org, read:user"
        echo "4. Click 'Generate token'"
        echo "5. Copy the token"
        echo ""
        read -p "Paste the token here: " TOKEN
        TOKEN_ID=""
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Error: Failed to create or retrieve token"
    if [ -f /tmp/token_response.json ]; then
        echo "Response:"
        cat /tmp/token_response.json
        rm /tmp/token_response.json
    fi
    exit 1
fi

# Save token to file
echo "$TOKEN" > "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"

# Save metadata for cleanup
cat > "$METADATA_FILE" <<EOF
TOKEN_NAME=$TOKEN_NAME
TOKEN_ID=$TOKEN_ID
CREATED_AT=$(date -Iseconds)
OUTPUT_FILE=$OUTPUT_FILE
EOF
chmod 600 "$METADATA_FILE"

# Cleanup temp file
rm -f /tmp/token_response.json

echo ""
echo "✅ Token created successfully!"
echo "   Saved to: $OUTPUT_FILE"
echo "   Metadata: $METADATA_FILE"
echo ""
echo "To use the token:"
echo "  export GITHUB_TOKEN=\$(cat $OUTPUT_FILE)"
echo "  gh api user --hostname github.com"
echo ""
echo "⚠️  Remember to run cleanup-token.sh after use to revoke the token!"
