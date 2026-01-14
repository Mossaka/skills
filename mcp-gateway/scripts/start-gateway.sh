#!/bin/bash
# Start MCP Gateway with GitHub MCP Server
# Version: Compatible with gh-aw-mcpg v0.0.59+

set -euo pipefail

# Configuration
GATEWAY_VERSION="${GATEWAY_VERSION:-v0.0.59}"
GATEWAY_PORT="${GATEWAY_PORT:-80}"
GATEWAY_DOMAIN="${GATEWAY_DOMAIN:-localhost}"
GATEWAY_API_KEY="${GATEWAY_API_KEY:-$(openssl rand -hex 16)}"
CONTAINER_NAME="${CONTAINER_NAME:-mcpg-gateway}"

echo "Starting MCP Gateway ${GATEWAY_VERSION}..."

# Get GitHub token
if [ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    echo "Getting GitHub token from gh CLI..."
    GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)
fi

# Create MCP Gateway configuration
echo "Creating gateway configuration..."
cat > /tmp/mcpg-config.json <<EOF
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "container": "ghcr.io/github/github-mcp-server:latest",
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  },
  "gateway": {
    "port": 8000,
    "domain": "${GATEWAY_DOMAIN}",
    "apiKey": "${GATEWAY_API_KEY}"
  }
}
EOF

# Clean up existing container
if docker ps -a --filter name=${CONTAINER_NAME} --format '{{.ID}}' | grep -q .; then
    echo "Removing existing container..."
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
fi

# Start the gateway
echo "Launching container..."
(cat /tmp/mcpg-config.json | docker run -i \
    --name ${CONTAINER_NAME} \
    -p ${GATEWAY_PORT}:8000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e "GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}" \
    -e "MCP_GATEWAY_PORT=8000" \
    -e "MCP_GATEWAY_DOMAIN=${GATEWAY_DOMAIN}" \
    -e "MCP_GATEWAY_API_KEY=${GATEWAY_API_KEY}" \
    ghcr.io/githubnext/gh-aw-mcpg:${GATEWAY_VERSION}) > /tmp/mcpg-gateway.log 2>&1 &

# Wait for gateway to be ready
echo "Waiting for gateway to start..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:${GATEWAY_PORT}/health >/dev/null 2>&1; then
        echo "✓ Gateway is running!"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo "✗ Gateway failed to start. Check logs:"
        echo "  docker logs ${CONTAINER_NAME}"
        exit 1
    fi
done

# Display information
echo ""
echo "========================================="
echo "MCP Gateway Information"
echo "========================================="
echo "Version:     ${GATEWAY_VERSION}"
echo "URL:         http://127.0.0.1:${GATEWAY_PORT}"
echo "Health:      http://127.0.0.1:${GATEWAY_PORT}/health"
echo "GitHub MCP:  http://127.0.0.1:${GATEWAY_PORT}/mcp/github"
echo "API Key:     ${GATEWAY_API_KEY}"
echo "Container:   ${CONTAINER_NAME}"
echo "Logs:        /tmp/mcpg-gateway.log"
echo ""
echo "To stop:"
echo "  docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}"
echo ""
echo "To check status:"
echo "  curl http://127.0.0.1:${GATEWAY_PORT}/health | jq ."
echo "========================================="

# Save API key for later use
echo "${GATEWAY_API_KEY}" > /tmp/mcpg-api-key.txt
