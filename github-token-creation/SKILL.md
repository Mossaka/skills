---
name: github-token-creation
description: "Create and manage read-only GitHub Personal Access Tokens (PATs) with automatic cleanup. Use when the user needs to: (1) Generate a temporary read-only GitHub token for one-time use, (2) Create tokens with minimal permissions for security, (3) Ensure tokens are properly revoked after use, or (4) Save GitHub tokens locally with proper permissions. Supports both fine-grained (recommended) and classic tokens."
---

# GitHub Token Creation

Create read-only GitHub Personal Access Tokens with automatic cleanup for one-time use.

## Quick Start

### Create a Token

```bash
scripts/create-token.sh [token-name] [output-file]
```

**Default behavior:**
- Token name: `readonly-pat-YYYYMMDD-HHMMSS`
- Output file: `~/.github-readonly-token`
- Permissions: Read-only (contents, metadata, pull requests, issues)

**Examples:**

```bash
# Create token with defaults
scripts/create-token.sh

# Create token with custom name
scripts/create-token.sh "my-readonly-token"

# Create token with custom output location
scripts/create-token.sh "ci-token" "/tmp/github-token"
```

### Use the Token

```bash
# Load token into environment
export GITHUB_TOKEN=$(cat ~/.github-readonly-token)

# Use with gh CLI
gh api user

# Use with git clone
git clone https://$(cat ~/.github-readonly-token)@github.com/owner/repo.git
```

### Cleanup After Use

**IMPORTANT:** Always run cleanup after using the token to revoke it from GitHub:

```bash
scripts/cleanup-token.sh [token-file]
```

This will:
1. Revoke the token from GitHub (for fine-grained tokens)
2. Delete local token file and metadata
3. Ensure the token cannot be reused

**Example:**

```bash
# Cleanup default token location
scripts/cleanup-token.sh

# Cleanup custom token location
scripts/cleanup-token.sh "/tmp/github-token"
```

## Token Types

### Fine-Grained Tokens (Recommended)

- More secure with granular permissions
- Can be scoped to specific repositories
- Can be revoked via API
- Default choice when running `create-token.sh`

**Permissions granted:**
- `contents: read` - Read repository contents
- `metadata: read` - Read repository metadata
- `pull_requests: read` - Read pull requests
- `issues: read` - Read issues

### Classic Tokens

- Legacy token type (being deprecated by GitHub)
- Broader scope permissions
- Cannot be revoked via API (must revoke manually via web UI)
- Use only if fine-grained tokens don't meet requirements

**Scopes recommended:**
- `public_repo` - Read-only access to public repositories
- `read:org` - Read organization membership
- `read:user` - Read user profile data

## Complete Workflow

**1. Create token before the operation:**

```bash
scripts/create-token.sh "my-operation-$(date +%Y%m%d)"
export GITHUB_TOKEN=$(cat ~/.github-readonly-token)
```

**2. Perform your operation:**

```bash
gh api repos/owner/repo
gh pr list --repo owner/repo
git clone https://$(cat ~/.github-readonly-token)@github.com/owner/repo.git
```

**3. Always cleanup after:**

```bash
scripts/cleanup-token.sh
unset GITHUB_TOKEN
```

## Security Best Practices

1. **One-time use:** Create a new token for each operation, then revoke immediately
2. **Minimal permissions:** Use read-only permissions unless write access is explicitly required
3. **File permissions:** Token files are automatically created with `600` permissions (owner read/write only)
4. **No version control:** Never commit token files to git
5. **Cleanup discipline:** Always run `cleanup-token.sh` after use

## Troubleshooting

**"gh CLI is not installed"**
- Install from https://cli.github.com/

**"Not authenticated with gh CLI"**
- Run `gh auth login` first

**"Could not revoke token from GitHub"**
- For classic tokens: Manually revoke at https://github.com/settings/tokens
- For fine-grained tokens: Token may already be revoked or expired

**Token not working**
- Verify permissions are sufficient for your operation
- Check token is correctly exported: `echo $GITHUB_TOKEN`
- Ensure token hasn't been revoked or expired

## File Structure

After creating a token, you'll have:

```
~/.github-readonly-token           # The actual token value
~/.github-readonly-token.metadata  # Token metadata (name, ID, creation date)
```

The metadata file enables automatic cleanup and revocation. Don't delete it manually - use `cleanup-token.sh` instead.
