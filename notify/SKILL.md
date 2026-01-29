---
name: notify
description: "Send notifications via clawdbot to WhatsApp. Use when: (1) Task is complete and user should be notified, (2) Long-running operation finished, (3) User says 'notify me' or 'send notification', (4) PR created or merged, (5) Tests pass/fail results."
---

# Notify

Send notifications to WhatsApp via clawdbot agent delivery.

## Usage

When you need to send a notification, use the following command:

```bash
clawdbot agent --to "+14439963942" --message "<your message>" --deliver
```

The agent will process your message and deliver a formatted response to WhatsApp.

## Examples

### Task Completion
```bash
clawdbot agent --to "+14439963942" --message "Task complete: Implemented user authentication. All tests pass. PR #123 ready for review." --deliver
```

### PR Created
```bash
clawdbot agent --to "+14439963942" --message "PR created: feat(auth): add OAuth support. Link: https://github.com/owner/repo/pull/123" --deliver
```

### Build Status
```bash
clawdbot agent --to "+14439963942" --message "Build failed: 3 tests failing in auth module. See CI logs for details." --deliver
```

### Status Update
```bash
clawdbot agent --to "+14439963942" --message "Status: Refactoring complete. 450 lines changed across 5 files. Ready for review." --deliver
```

## Message Guidelines

- Keep messages concise but informative
- Include relevant links (PRs, issues, docs)
- Mention key metrics (test count, lines changed, etc.)
- State the action needed (review, merge, fix, etc.)

## Alternative Methods

| Method | Command | Use Case |
|--------|---------|----------|
| **Agent delivery** (recommended) | `clawdbot agent --to "..." --message "..." --deliver` | Agent formats and delivers |
| **Direct message** | `clawdbot message send --channel whatsapp --target "..." --message "..."` | Send exact message |
| **System event** | `clawdbot system event --text "..." --mode now` | Queue for heartbeat |

## Notes

- The agent processes the message before delivery, so responses are formatted nicely
- Messages are delivered to WhatsApp immediately with `--deliver`
- The target phone number is in E.164 format (+14439963942)
