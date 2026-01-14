#!/bin/bash
# Quick scan for common errors in agentic workflow logs
#
# Usage: ./quick_scan.sh <log-directory>
# Example: ./quick_scan.sh .github/aw/logs/run-21005890162

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <log-directory>"
    echo "Example: $0 .github/aw/logs/run-21005890162"
    exit 1
fi

LOG_DIR="$1"
AGENT_LOG="$LOG_DIR/agent-stdio.log"
GATEWAY_LOG="$LOG_DIR/mcp-logs/gateway.md"
FIREWALL_LOG="$LOG_DIR/sandbox/firewall/logs/access.log"

echo "=== Quick Scan for Common Errors ==="
echo "Log directory: $LOG_DIR"
echo ""

# Check if agent log exists
if [ ! -f "$AGENT_LOG" ]; then
    echo "⚠️  Agent log not found at: $AGENT_LOG"
    exit 1
fi

echo "🔍 Scanning for MCP server failures..."
MCP_FAILURES=$(grep -c "mcp:.*failed" "$AGENT_LOG" 2>/dev/null || echo "0")
if [ "$MCP_FAILURES" -gt 0 ]; then
    echo "   ❌ Found $MCP_FAILURES MCP server failure(s)"
    grep -E "mcp:.*failed" "$AGENT_LOG" | head -5
else
    echo "   ✅ No MCP server failures"
fi
echo ""

echo "🔍 Scanning for DNS resolution errors..."
DNS_ERRORS=$(grep -c "dns error.*Name does not resolve" "$AGENT_LOG" 2>/dev/null || echo "0")
if [ "$DNS_ERRORS" -gt 0 ]; then
    echo "   ❌ Found $DNS_ERRORS DNS resolution error(s)"
    echo "   This usually indicates host.docker.internal is not resolvable"
else
    echo "   ✅ No DNS resolution errors"
fi
echo ""

echo "🔍 Scanning for OAuth/keyring warnings..."
OAUTH_WARNS=$(grep -c "WARN codex_rmcp_client::oauth" "$AGENT_LOG" 2>/dev/null || echo "0")
if [ "$OAUTH_WARNS" -gt 0 ]; then
    echo "   ⚠️  Found $OAUTH_WARNS OAuth warning(s)"
    echo "   This may indicate missing org.freedesktop.secrets service"
else
    echo "   ✅ No OAuth warnings"
fi
echo ""

echo "🔍 Scanning for tool availability errors..."
TOOL_ERRORS=$(grep -ic "tool.*not available\|tool.*failed" "$AGENT_LOG" 2>/dev/null || echo "0")
if [ "$TOOL_ERRORS" -gt 0 ]; then
    echo "   ❌ Found $TOOL_ERRORS tool error(s)"
    grep -i "tool.*not available\|tool.*failed" "$AGENT_LOG" | head -3
else
    echo "   ✅ No tool availability errors"
fi
echo ""

# Check MCP Gateway logs if they exist
if [ -f "$GATEWAY_LOG" ]; then
    echo "🔍 Scanning MCP Gateway logs..."
    SESSION_ERRORS=$(grep -c "Session not found" "$GATEWAY_LOG" 2>/dev/null || echo "0")
    if [ "$SESSION_ERRORS" -gt 0 ]; then
        echo "   ⚠️  Found $SESSION_ERRORS session error(s)"
        grep "Session not found" "$GATEWAY_LOG" | head -3
    else
        echo "   ✅ No session errors"
    fi
    echo ""
fi

# Check firewall logs if they exist
if [ -f "$FIREWALL_LOG" ]; then
    echo "🔍 Scanning firewall logs..."
    BLOCKED=$(grep -c "TCP_DENIED" "$FIREWALL_LOG" 2>/dev/null || echo "0")
    if [ "$BLOCKED" -gt 0 ]; then
        echo "   ⚠️  Found $BLOCKED blocked request(s)"
        grep "TCP_DENIED" "$FIREWALL_LOG" | head -3
    else
        echo "   ✅ No blocked requests"
    fi
    echo ""
fi

echo "=== Scan Complete ==="
