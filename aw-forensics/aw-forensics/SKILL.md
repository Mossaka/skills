---
name: aw-forensics
description: "Forensic analysis of GitHub Agentic Workflow runs using gh aw logs and gh aw audit. Use when: (1) Investigating why agentic workflows failed across multiple runs, (2) User says 'forensic analysis' or 'analyze workflow runs', (3) Comparing workflow behavior across time periods or code changes, (4) Diagnosing systematic issues with a specific engine (claude, copilot, codex, gemini), (5) Auditing MCP server connectivity, tool usage, and safe outputs across runs."
---

# Agentic Workflow Forensic Analysis

Analyze multiple agentic workflow runs to identify systematic failures, verify fixes, and produce structured reports.

## Workflow

### 1. Collect Runs with `gh aw logs`

```bash
# Fetch runs for a specific workflow (use workflow name from gh aw status)
gh aw logs "<Workflow Name>" --count 10 --parse

# Filter by engine
gh aw logs "<Workflow Name>" --count 10 --engine gemini

# Filter by date range
gh aw logs "<Workflow Name>" --count 20 --start-date -7d

# Filter by repo (when not in the workflow's repo)
gh aw logs "<Workflow Name>" --count 10 --repo owner/repo

# JSON output for programmatic analysis
gh aw logs "<Workflow Name>" --count 10 --json
```

Note the overview table output: Run ID, Status, Duration, Tokens, Turns, Errors, Warnings, Missing Tools, Missing Data, Safe Items. **Zero tokens + zero turns = agent never executed.**

### 2. Audit Individual Runs with `gh aw audit`

```bash
# Audit a specific run
gh aw audit <RUN_ID>

# JSON output for structured data
gh aw audit <RUN_ID> --json

# Audit from a URL
gh aw audit https://github.com/owner/repo/actions/runs/<RUN_ID>
```

This downloads artifacts: `agent-stdio.log`, `aw_info.json`, `prompt.txt`, `safe_output.jsonl`, workflow logs.

### 3. Analyze Downloaded Artifacts

For each run, read the downloaded files at `.github/aw/logs/run-<RUN_ID>/`:

**`aw_info.json`** - Metadata:
- `engine_id`: Which engine (claude, copilot, codex, gemini)
- `cli_version`: gh-aw compiler version
- `firewall_enabled`: Whether AWF was active
- `awf_version`, `awmg_version`: Firewall and gateway versions
- `allowed_domains`: Network permissions
- `event_name`: What triggered the run

**`agent-stdio.log`** - The full agent execution log. Search for failure patterns described in [references/failure-patterns.md](references/failure-patterns.md).

**`safe_output.jsonl`** - Safe output calls (add_comment, create_issue, add_labels, etc.). Empty = agent never called safe outputs.

### 4. Categorize Failures

For each run, determine:
- **Fix state**: What version of the code was running? Map runs to known fixes.
- **Failure category**: Use patterns from [references/failure-patterns.md](references/failure-patterns.md).
- **Agent progress**: Did the agent start? Make API calls? Execute tools? Produce output?

### 5. Produce the Report

Structure the report as:

**Timeline table**: All runs sorted by date with columns: Run ID, Date, Repo, Branch, Event, Fix State, Failure Category.

**Failure category summary**: Count of each failure type across runs.

**Fix verification matrix**: For each known bug/fix, which runs demonstrate it's resolved?

**Remaining issues**: Issues that persist after all known fixes.

**Recommendations**: Concrete next steps.

## Useful Queries

```bash
# Get workflow run job details
gh run view <RUN_ID> --repo owner/repo --json jobs --jq '.jobs[] | {name, conclusion}'

# Get failed step names
gh run view <RUN_ID> --repo owner/repo --json jobs \
  --jq '.jobs[] | select(.conclusion == "failure") | {name, steps: [.steps[] | select(.conclusion == "failure") | .name]}'

# Search agent logs for specific patterns
gh run view <RUN_ID> --repo owner/repo --log 2>&1 | grep "agent.*Run" | grep -iE "error|denied|quota|Unknown"

# Check MCP gateway connectivity in logs
gh run view <RUN_ID> --repo owner/repo --log 2>&1 | grep "Start MCP Gateway" | grep -iE "connected|failed|error"

# Check MCP server discovery by agent
gh run view <RUN_ID> --repo owner/repo --log 2>&1 | grep "supports tool updates"
```
