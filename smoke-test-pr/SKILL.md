---
name: smoke-test-pr
description: "Trigger and monitor smoke tests for a gh-aw PR. Use when: (1) User wants to run smoke/integration tests on a PR, (2) User says 'run smoke tests' or 'trigger smoke', (3) Validating that gh-aw changes don't break basic workflows, (4) Need to verify MCP server connectivity and agent behavior in workflows."
---

# Smoke Test PR

Triggers smoke tests on a gh-aw PR by toggling the "smoke" label, then monitors workflow execution and analyzes logs to determine true success or failure.

## Why This Matters

Smoke tests are the **only integration tests** for gh-aw that verify changes don't break basic agentic workflows. A green workflow status is NOT sufficient - you must analyze the logs to catch silent failures.

## Instructions

When the user invokes this skill with a PR URL or number, perform these steps:

### 1. Trigger Smoke Tests

Toggle the "smoke" label to trigger the smoke workflows:

```bash
# Remove label if present, then add it
gh pr edit <PR_NUMBER> --remove-label "smoke" --repo <OWNER/REPO> 2>/dev/null || true
sleep 2
gh pr edit <PR_NUMBER> --add-label "smoke" --repo <OWNER/REPO>
```

### 2. Wait for Workflows to Start

Wait a few seconds for GitHub Actions to pick up the label event:

```bash
sleep 10
```

### 3. Monitor Workflow Runs

List the workflow runs for this PR and wait for smoke workflows to complete:

```bash
# Get the PR's head SHA
HEAD_SHA=$(gh pr view <PR_NUMBER> --repo <OWNER/REPO> --json headRefOid -q '.headRefOid')

# List workflow runs for this commit
gh run list --repo <OWNER/REPO> --commit $HEAD_SHA --json name,status,conclusion,databaseId
```

Key smoke workflows to monitor:
- `smoke-copilot`
- `smoke-claude`
- `smoke-codex`
- Any workflow with "smoke" in the name

Wait for these workflows to complete (status changes from "in_progress" to "completed"):

```bash
# Watch a specific run until completion
gh run watch <RUN_ID> --repo <OWNER/REPO>
```

### 4. Fetch and Analyze Logs (CRITICAL)

**Do NOT trust the workflow conclusion alone.** Even if the workflow shows "success", you must analyze the logs.

#### Fetch workflow logs:

```bash
gh run view <RUN_ID> --repo <OWNER/REPO> --log
```

#### Check for these failure indicators in logs:

**MCP Server Connection Failures:**
- `MCP server .* failed to connect`
- `Failed to initialize MCP`
- `MCP connection timeout`
- `tools: []` or empty tool list when tools were expected
- `No tools available`

**Agent Execution Failures:**
- `Agent failed to`
- `Could not complete task`
- `Error executing`
- `Permission denied`
- `Rate limit exceeded`

**Firewall/Network Issues:**
- `SQUID_BLOCK` or blocked domain messages
- `Connection refused`
- `Network unreachable`
- `Firewall denied`

**Silent Failures:**
- Agent claims success but didn't actually perform the requested action
- Missing expected output files or artifacts
- Workflow completed but agent output shows confusion or inability to proceed

### 5. Fetch Firewall Logs (if available)

For workflows using the agentic firewall, check firewall logs for blocked requests:

```bash
# Download workflow artifacts
gh run download <RUN_ID> --repo <OWNER/REPO> --name firewall-logs -D /tmp/firewall-logs

# Or view logs in the workflow output looking for awf/firewall output
```

### 6. Report Results

Provide a comprehensive report:

1. **Workflow Status**: List each smoke workflow and its GitHub status
2. **True Result**: Your assessment after log analysis (PASS/FAIL)
3. **Issues Found**: Any problems detected in logs
4. **MCP Status**: Were all expected MCP servers connected?
5. **Agent Behavior**: Did the agent perform the expected tasks?
6. **Firewall Issues**: Any blocked requests that might indicate problems?

## Example Report Format

```
## Smoke Test Results for PR #12062

### Workflow Runs
| Workflow | GitHub Status | True Result |
|----------|---------------|-------------|
| smoke-copilot | success | PASS |
| smoke-claude | success | FAIL |

### Issues Found
- smoke-claude: MCP server 'github' failed to connect (line 234)
- smoke-claude: Agent reported "No tools available" (line 456)

### Recommendation
PR has smoke test failures. The claude engine MCP integration is broken.
```

## Usage Examples

```
/smoke-test-pr https://github.com/githubnext/gh-aw/pull/12062
/smoke-test-pr 12062
```

## Important Notes

- Always analyze logs, never trust green status alone
- MCP server connectivity issues are common silent failures
- Check that the agent actually performed the task, not just claimed to
- Firewall blocks can cause workflows to "succeed" while actually failing
- Report both the GitHub status AND your true assessment
