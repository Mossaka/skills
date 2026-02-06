---
name: delegate-sidequest
description: "Delegate minor issues to Copilot instead of getting distracted. Use PROACTIVELY when: (1) You notice a bug, code smell, or improvement while working on a main task, (2) You spot something wrong but fixing it would derail your current focus, (3) You find TODOs, tech debt, or minor issues that should be tracked. This skill helps agents stay focused on the primary task by offloading side quests to GitHub Copilot."
---

# Delegate Side Quests to Copilot

## Purpose

When working on a main feature or task, you will inevitably notice minor issues — bugs, code smells, missing tests, outdated docs, tech debt, etc. **Do NOT get distracted.** Instead, delegate these side quests to GitHub Copilot so you can stay focused on your primary objective.

This is a behavioral skill. You should apply it **proactively** throughout your work without being asked.

## When to Delegate

Delegate when you notice ANY of these while working on your main task:

- A bug or broken behavior unrelated to your current work
- Code that needs refactoring but isn't blocking you
- Missing or outdated tests for existing code
- Documentation that's wrong or missing
- TODOs or FIXMEs in the codebase
- Accessibility issues
- Minor UI inconsistencies
- Type errors or lint warnings in unrelated files
- Dependency updates needed
- Dead code that should be cleaned up

## When NOT to Delegate

Do NOT delegate if:

- The issue is directly part of your current task (just fix it)
- The issue blocks your current work (fix it or raise it to the user)
- It involves security-sensitive changes (flag to the user instead)
- It requires architectural decisions the user should make

## How to Delegate

You have **two methods**. Choose based on context:

### Method 1: Create a GitHub Issue assigned to Copilot (Preferred)

Use this when the side quest is well-defined and would benefit from being tracked as an issue.

```bash
gh issue create \
  --assignee "@copilot" \
  --title "Short descriptive title of the issue" \
  --body "$(cat <<'EOF'
## Context

[Where you found this issue and what you were doing]

## Problem

[Clear description of what's wrong or what needs to change]

## Expected Behavior

[What the correct behavior should be]

## Suggested Fix

[If you have an idea of how to fix it, describe it here. Include file paths, function names, and specific guidance.]

## Acceptance Criteria

- [ ] [Specific, testable criterion]
- [ ] [Tests pass]
- [ ] [No regressions]
EOF
)"
```

You can also assign Copilot to an existing issue:

```bash
gh issue edit <issue-number> --add-assignee "@copilot"
```

### Method 2: Create an Agent Task directly

Use this when you want Copilot to just do the work immediately without creating a trackable issue. Good for quick, straightforward fixes.

```bash
gh agent-task create "$(cat <<'EOF'
<Detailed description of what needs to be done.
Include:
- Which files to modify
- What the current behavior is
- What the expected behavior should be
- Any relevant code snippets or patterns to follow
- How to verify the fix (run tests, lint, etc.)>
EOF
)"
```

Options:
- `--base <branch>` — target a specific base branch for the PR
- `--follow` — follow the agent's progress in real time
- `--custom-agent <name>` — use a custom agent defined in `.github/agents/<name>.md`
- `-R owner/repo` — target a different repository

### Quick one-liner for simple fixes

```bash
gh agent-task create "Fix the typo in src/utils/helper.ts line 42: 'recieve' should be 'receive'"
```

## Writing Good Delegations

Follow the **WRAP** principles for issues assigned to Copilot:

1. **Write clearly** — Write as if briefing a new team member. Include background, expected outcome, and technical details.
2. **Refine with context** — Reference specific files, functions, and line numbers. The more precise, the better.
3. **Atomic tasks** — One issue per side quest. Don't bundle multiple unrelated fixes.
4. **Pair via PR comments** — After Copilot creates a PR, you (or the user) can iterate by commenting with `@copilot`.

## Behavioral Guidelines

1. **Always tell the user** — When you delegate a side quest, inform the user briefly:
   > "I noticed [issue] in [file]. This isn't related to our current task, so I've created a GitHub issue and assigned it to Copilot: [issue URL]"

2. **Don't over-delegate** — Only delegate genuine issues worth fixing. Don't create noise.

3. **Stay focused** — After delegating, immediately return to your main task. Do not follow up on the delegated issue.

4. **Keep a mental tally** — If you're finding many issues in one area, mention it to the user as it might indicate a larger problem worth discussing.

5. **Label issues when possible** — Add labels to help categorize:
   ```bash
   gh issue create --assignee "@copilot" --label "bug,tech-debt" --title "..." --body "..."
   ```

## Example Workflow

You're implementing a new API endpoint and notice:

1. A utility function has a typo in its name → **Delegate**:
   ```bash
   gh issue create --assignee "@copilot" \
     --title "Rename misspelled function 'calcualteTotal' to 'calculateTotal' in src/utils/math.ts" \
     --body "The function 'calcualteTotal' on line 15 of src/utils/math.ts is misspelled. Rename it to 'calculateTotal' and update all call sites. Run tests to verify nothing breaks."
   ```
   Tell the user: "I noticed a misspelled function name in src/utils/math.ts. Created an issue and assigned to Copilot."

2. Some tests are missing for an existing helper → **Delegate**:
   ```bash
   gh agent-task create "Add unit tests for the 'formatDate' function in src/utils/date.ts. Currently it has no test coverage. Test edge cases: null input, invalid dates, timezone handling, and standard ISO format output. Follow the existing test patterns in src/utils/__tests__/."
   ```
   Tell the user: "I noticed formatDate has no test coverage. Delegated a task to Copilot to add tests."

3. The endpoint you're building has a validation bug → **Fix it yourself** (it's your current task).

4. You find a potential SQL injection in an unrelated file → **Tell the user directly** (security issue, don't just delegate).

## What Happens After Delegation

- **For issues**: Copilot reacts with an eyes emoji, creates a branch and draft PR, works autonomously, then requests review.
- **For agent tasks**: Copilot immediately starts working and creates a draft PR.
- **The user** (or a reviewer) must approve the PR before it merges. Copilot PRs require human review.
- **You can check status** with `gh agent-task list` or `gh issue list --assignee @copilot`, but only if the user asks. Don't check proactively — stay focused on your main task.
