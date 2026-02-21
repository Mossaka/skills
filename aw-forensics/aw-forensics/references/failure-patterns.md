# Failure Patterns Reference

Patterns to search for in `agent-stdio.log` and workflow logs, organized by category.

## Engine Startup Failures

**CLI flag rejection** (agent never starts):
```
Unknown arguments: <flag-name>
Usage: <engine> [options] [command]
```
Cause: Compiled workflow passes unsupported CLI flag. Fix in gh-aw engine compiler.

**Binary not found**:
```
command not found: <engine-name>
```
Cause: Engine CLI not installed. Check installation step.

## MCP Server Issues

**MCP servers connected** (healthy):
```
Server '<name>' supports tool updates. Listening for changes...
```

**MCP gateway connected** (healthy):
```
✓ <server-name>: connected
✓ All checks passed (N succeeded, 0 skipped)
```

**MCP connection failure**:
```
MCP server .* failed to connect
Failed to initialize MCP
MCP connection timeout
```

**Tool execution denied** (Gemini-specific):
```
Error executing tool <name>: Tool execution denied by policy.
```
Cause: Missing `--yolo` or `--approval-mode yolo` flag. Gemini CLI defaults to requiring approval.

**Tool not found**:
```
Tool "<name>" not found. Did you mean one of: <suggestions>
```
Cause: MCP server doesn't expose the tool the agent tried to call.

## API / Quota Errors

**Quota exhaustion** (Gemini):
```
TerminalQuotaError: You have exhausted your daily quota on this model.
Quota exceeded for metric: .* limit: \d+, model: .*
```

**Rate limiting** (various engines):
```
Rate limit exceeded
429 Too Many Requests
```

**Service unavailable**:
```
503.*Service Unavailable
upstream connect error or disconnect/reset
This model is currently experiencing high demand
```

**Authentication failure**:
```
401 Unauthorized
Invalid API key
ANTHROPIC_API_KEY.*invalid
```

## Firewall / Network Issues

**Domain blocked by Squid**:
```
TCP_DENIED
SQUID_BLOCK
Connection refused
```

**DNS failure**:
```
Could not resolve host
Name or service not known
```

## Safe Outputs

**Safe outputs invoked** (healthy):
Check `safe_output.jsonl` exists and is non-empty.

**Safe outputs validation failed**:
```
No safe outputs were invoked
Agent did not call add_comment
```

## Progress Indicators

Use these to gauge how far the agent got:

| Indicator | Meaning |
|-----------|---------|
| 0 tokens, 0 turns | Agent never made an API call |
| Tokens > 0, 0 tool calls | Agent ran but didn't use tools |
| Tool calls present | Agent executed tools |
| safe_output.jsonl non-empty | Agent produced safe outputs |
| detection job passed | Threat detection completed |
| safe_outputs job passed | Output validation completed |
