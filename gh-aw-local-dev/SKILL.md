---
name: gh-aw-local-dev
description: Understanding gh-aw local dev mode - why workflows need actions/setup folder copied and how to fix it
allowed-tools: Bash, Read, Write, Glob, Grep
---

# gh-aw Local Dev Mode

When building and using gh-aw locally (not from a release), compiled workflows require the `actions/setup` folder to be copied into target repositories. This skill explains why and how to handle it.

## The Problem

When you run `gh aw compile` with a locally-built gh-aw binary, the compiled `.lock.yml` workflow references local actions:

```yaml
- name: Setup Scripts
  uses: ./actions/setup   # <-- Local path reference!
```

This fails on GitHub Actions because the `actions/setup` folder doesn't exist in the target repository.

## Why This Happens

gh-aw has three **action modes**:

| Mode | Reference | When Used |
|------|-----------|-----------|
| `dev` | `./actions/setup` (local) | Locally-built binary (default for development) |
| `release` | `githubnext/gh-aw/actions/setup@vX.X.X` (remote) | Official releases |
| `inline` | Scripts embedded in workflow | Special cases |

The mode is auto-detected based on:
1. `GH_AW_ACTION_MODE` environment variable
2. Whether binary was built with release flag (`IsRelease()`)
3. GitHub Actions context (release branch/tag)

**Locally-built binaries default to `dev` mode**, which generates local action references.

## Solutions

### Solution 1: Copy actions folder (Quick fix for local testing)

Copy the `actions/` folder from gh-aw repo to the target repository:

```bash
# From the target repository
cp -r /path/to/gh-aw/actions ./actions/
git add actions/
git commit -m "Add gh-aw actions for local development"
git push
```

### Solution 2: Use release mode (Recommended for production)

Compile with explicit release mode:

```bash
gh aw compile --action-mode release .github/workflows/my-workflow.md
```

This generates references to the remote action:
```yaml
- name: Setup Scripts
  uses: githubnext/gh-aw/actions/setup@v0.37.0
```

**Note:** The version tag must exist on GitHub. If using a dev version like `v0.37.32-18-g0dab83668`, pinning will fail.

### Solution 3: Set environment variable

For all compilations in a session:

```bash
export GH_AW_ACTION_MODE=release
gh aw compile .github/workflows/my-workflow.md
```

## Checking Current Mode

To see which mode was used in a compiled workflow:

```bash
# Dev mode - local reference
grep "uses: ./actions/setup" .github/workflows/*.lock.yml

# Release mode - remote reference
grep "uses: githubnext/gh-aw/actions/setup@" .github/workflows/*.lock.yml
```

## Common Scenarios

### Scenario: Testing forks of OSS repos locally

When forking OSS repos and adding agentic workflows with a local gh-aw build:

1. Fork and clone the repo
2. Run `gh aw init` and create workflow
3. Run `gh aw compile` (uses dev mode by default)
4. **Copy actions folder**: `cp -r /path/to/gh-aw/actions ./actions/`
5. Commit and push everything including `actions/`
6. Workflow will now run successfully

### Scenario: CI/CD with official gh-aw

When using official gh-aw releases in CI/CD:
- No action needed - release mode is auto-detected
- Workflows reference remote `githubnext/gh-aw/actions/setup@vX.X.X`

### Scenario: Mixed local dev and CI

If developing locally but want CI-compatible workflows:
- Always use `--action-mode release` when compiling
- Or set `GH_AW_ACTION_MODE=release` in your shell profile

## Files in actions/ Folder

The `actions/` folder contains:

```
actions/
├── setup/              # Main action with JavaScript/shell scripts
│   ├── action.yml
│   ├── js/            # JavaScript action implementations
│   └── sh/            # Shell scripts
└── setup-cli/         # CLI installation action
    └── install.sh
```

These scripts handle:
- Setting up the gh-aw runtime environment
- Validating secrets and tokens
- Starting MCP gateway
- Managing agent execution
- Parsing logs and generating summaries

## Troubleshooting

### Error: "Can't find 'action.yml' in './actions/setup'"

**Cause:** Workflow was compiled in dev mode but actions folder is missing.

**Fix:** Copy actions folder or recompile with `--action-mode release`.

### Warning: "Unable to pin action githubnext/gh-aw/actions/setup@vX.X.X"

**Cause:** Using release mode with a version tag that doesn't exist on GitHub.

**Fix:** Use a valid release tag or switch to dev mode for local testing.

### Workflow runs locally but fails in CI

**Cause:** Local setup differs from CI environment.

**Fix:** Ensure CI uses same gh-aw version or use release mode for consistent behavior.

## Quick Reference

```bash
# Check current action mode in compiled workflow
grep -E "uses: (./|githubnext/gh-aw/)actions/setup" .github/workflows/*.lock.yml

# Compile in release mode
gh aw compile --action-mode release .github/workflows/workflow.md

# Force release mode for session
export GH_AW_ACTION_MODE=release

# Copy actions folder for dev mode
cp -r ~/path/to/gh-aw/actions ./actions/
```
