#!/bin/bash
# Stop MCP Gateway

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-mcpg-gateway}"

echo "Stopping MCP Gateway..."

if docker ps -a --filter name=${CONTAINER_NAME} --format '{{.ID}}' | grep -q .; then
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    echo "✓ Gateway stopped and removed"
else
    echo "⚠ Container '${CONTAINER_NAME}' not found"
fi

# Clean up any orphaned MCP server containers
echo "Cleaning up MCP server containers..."
docker ps -a --format '{{.Names}}' | grep -E 'github-mcp|mcp-server' | while read container; do
    docker rm -f "$container" 2>/dev/null || true
    echo "  Removed: $container"
done

echo "✓ Cleanup complete"
