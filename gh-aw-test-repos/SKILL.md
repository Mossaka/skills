---
name: gh-aw-test-repos
description: "Guide for setting up OSS repositories to test GitHub Agentic Workflows (gh-aw). Use when: (1) Setting up test repos for agentic workflows, (2) Forking and initializing repos with gh-aw, (3) Creating build/test workflows for Go or other languages, (4) Troubleshooting gh aw init issues (TTY, missing actions folder), (5) Monitoring workflow runs on forked repos."
---

# Setting Up Test Repositories for gh-aw Agentic Workflows

## Overview

Guide for setting up OSS repositories to test GitHub Agentic Workflows (gh-aw). Covers forking, initializing with gh-aw, creating workflows, and monitoring.

## Workflow

### 1. Select and Clone Repositories

Choose small-to-medium repos with good test coverage:
- Go: `fatih/color`, `gofrs/uuid`, `caarlos0/env`
- Look for: existing CI, clear build commands, active maintenance

```bash
mkdir -p /path/to/test-repos && cd /path/to/test-repos
gh repo clone owner/repo
```

### 2. Fork to Your Account

```bash
cd repo-name
gh repo fork --remote=true
# Sets origin to your fork, upstream to original
```

### 3. Initialize with gh-aw

**Known Issue**: `gh aw init` requires TTY. If unavailable, manually create:

```bash
# Create .gitattributes
echo "*.lock.yml linguist-generated=true" > .gitattributes

# Create logs gitignore
mkdir -p .github/aw/logs
echo "*" > .github/aw/logs/.gitignore
echo "!.gitignore" >> .github/aw/logs/.gitignore

# Copy actions folder from gh-aw repo (REQUIRED)
cp -r /path/to/gh-aw/actions ./actions
```

**Critical**: The `actions/setup` folder must exist for workflows to run.

### 4. Create Agentic Workflow

Create `.github/workflows/build-test.md`:

```markdown
---
name: Build and Test
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:
permissions:
  contents: read
engine: copilot
network:
  allowed:
    - defaults
    - node
    - github
    - go  # or appropriate language
tools:
  bash:
    - "*"
  edit:
timeout-minutes: 10
---

# Build and Test

Instructions for building and testing the project...
```

**Frontmatter fields**:
- `engine: copilot` - Use Copilot as the AI engine
- `network.allowed` - AWF firewall domains (defaults, node, github, + language-specific)
- `tools.bash` - Allow all bash commands
- `workflow_dispatch` - Enable manual triggering

### 5. Compile Workflow

```bash
gh aw compile .github/workflows/build-test.md
# Creates build-test.lock.yml
```

### 6. Commit and Push

```bash
git add .
git commit -m "Add agentic workflow for build and test"
git push origin main
```

### 7. Add Secrets

```bash
gh secret set COPILOT_GITHUB_TOKEN -b "your_token_here" --repo owner/repo
```

### 8. Trigger and Monitor

```bash
# Manual trigger
gh workflow run build-test.lock.yml --repo owner/repo

# Monitor
gh run list --repo owner/repo --workflow=build-test.lock.yml
gh run watch --repo owner/repo <run-id>
```

## Common Issues

| Issue | Solution |
|-------|----------|
| `gh aw init` needs TTY | Manually create files (see Step 3) |
| Missing actions/setup | Copy from gh-aw repo |
| `pull_request: null` error | Add `types: [opened, synchronize, reopened]` |
| Workflow not found | Use `--repo owner/fork` flag explicitly |
| gh commands hit upstream | Set origin correctly with `gh repo fork --remote=true` |

## Go Project Workflow Example

```markdown
---
name: Build and Test
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:
permissions:
  contents: read
engine: copilot
network:
  allowed:
    - defaults
    - node
    - github
    - go
tools:
  bash:
    - "*"
  edit:
timeout-minutes: 10
---

# Build and Test Go Project

## Instructions

1. Run `go version` to verify Go is available
2. Run `go mod download` to fetch dependencies
3. Run `go build ./...` to compile all packages
4. Run `go test -v ./...` to run all tests
5. Report build/test results
```
