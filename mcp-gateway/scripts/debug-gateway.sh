#!/bin/bash
# Debug and Troubleshoot MCP Gateway

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-mcpg-gateway}"

echo "========================================"
echo "MCP Gateway Debug Information"
echo "========================================"
echo

# Check if container exists
if ! docker ps -a --filter name=${CONTAINER_NAME} --format '{{.ID}}' | grep -q .; then
    echo "✗ Container '${CONTAINER_NAME}' not found"
    echo ""
    echo "Start the gateway first:"
    echo "  ./start-gateway.sh"
    exit 1
fi

# Container status
echo "=== Container Status ==="
docker ps -a --filter name=${CONTAINER_NAME} --format "ID: {{.ID}}\nImage: {{.Image}}\nStatus: {{.Status}}\nPorts: {{.Ports}}"
echo

# Health check
echo "=== Health Check ==="
if curl -s http://127.0.0.1:80/health >/dev/null 2>&1; then
    curl -s http://127.0.0.1:80/health | jq .
    echo "✓ Gateway is healthy"
else
    echo "✗ Gateway health check failed"
fi
echo

# Gateway logs
echo "=== Gateway Logs (last 50 lines) ==="
docker logs ${CONTAINER_NAME} 2>&1 | tail -50
echo

# Check MCP server containers
echo "=== MCP Server Containers ==="
docker ps --format "{{.Names}}: {{.Image}} ({{.Status}})" | grep -E 'github-mcp|mcp-server' || echo "No MCP server containers found"
echo

# Internal log files
echo "=== Internal Log Files ==="
docker exec ${CONTAINER_NAME} ls -lh /tmp/gh-aw/mcp-logs/ 2>/dev/null || echo "Cannot access log directory"
echo

# Check for common issues
echo "=== Common Issues Check ==="

# Check 1: Environment variables
echo -n "GITHUB_PERSONAL_ACCESS_TOKEN set: "
if docker exec ${CONTAINER_NAME} printenv GITHUB_PERSONAL_ACCESS_TOKEN >/dev/null 2>&1; then
    echo "✓ Yes"
else
    echo "✗ No (this may cause authentication issues)"
fi

# Check 2: Docker socket
echo -n "Docker socket accessible: "
if docker exec ${CONTAINER_NAME} test -S /var/run/docker.sock 2>/dev/null; then
    echo "✓ Yes"
else
    echo "✗ No (cannot spawn MCP server containers)"
fi

# Check 3: Port binding
echo -n "Port 80 bound: "
if netstat -tln 2>/dev/null | grep -q ':80 ' || ss -tln 2>/dev/null | grep -q ':80 '; then
    echo "✓ Yes"
else
    echo "⚠ Port 80 not listening"
fi

echo
echo "========================================"
echo "For detailed logs:"
echo "  docker logs ${CONTAINER_NAME}"
echo "  docker logs ${CONTAINER_NAME} -f  # follow mode"
echo ""
echo "To restart gateway:"
echo "  docker restart ${CONTAINER_NAME}"
echo "========================================"
