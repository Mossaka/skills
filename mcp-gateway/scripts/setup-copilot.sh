#!/bin/bash
# Setup Copilot CLI to use MCP Gateway

set -euo pipefail

GATEWAY_PORT="${GATEWAY_PORT:-80}"
API_KEY="${API_KEY:-$(cat /tmp/mcpg-api-key.txt 2>/dev/null || echo 'test-api-key')}"

echo "Creating Copilot MCP configuration..."

# Create MCP config for Copilot CLI
cat > /tmp/mcp-gateway-config.json <<EOF
{
  "mcpServers": {
    "github-gateway": {
      "type": "http",
      "url": "http://host.docker.internal:${GATEWAY_PORT}/mcp/github",
      "headers": {
        "Authorization": "${API_KEY}"
      },
      "tools": ["*"]
    }
  }
}
EOF

echo "✓ Created /tmp/mcp-gateway-config.json"
echo ""
echo "To use with Copilot CLI (outside AWF):"
echo "  npx @github/copilot \\"
echo "    --disable-builtin-mcps \\"
echo "    --additional-mcp-config @/tmp/mcp-gateway-config.json \\"
echo "    --allow-all-tools \\"
echo "    --prompt 'List 3 issues from githubnext/gh-aw'"
echo ""
echo "To use with AWF:"
echo "  sudo -E awf \\"
echo "    --enable-host-access \\"
echo "    --mount /tmp:/tmp:rw \\"
echo "    --allow-domains 'host.docker.internal,api.github.com,*.githubusercontent.com' \\"
echo "    -- npx -y @github/copilot \\"
echo "      --disable-builtin-mcps \\"
echo "      --additional-mcp-config @/tmp/mcp-gateway-config.json \\"
echo "      --allow-all-tools \\"
echo "      --prompt 'Your prompt here'"
