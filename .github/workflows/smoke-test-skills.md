---
description: Smoke test to verify all skills in the repository are properly configured and accessible
on:
  schedule: daily
  workflow_dispatch:
permissions:
  contents: read
  actions: read
tools:
  bash:
    - "ls -la */"
    - "find . -name 'SKILL.md' -type f"
    - "ls -d */"
    - "cat */SKILL.md"
    - "python* */scripts/quick_validate.py *"
safe-outputs:
  create-issue:
    title-prefix: "[smoke-test] "
    labels: [automation, smoke-test]
    expires: 7
timeout-minutes: 5
---

# Skills Repository Smoke Test

You are an AI agent that performs smoke tests on the skills repository to ensure all skills are properly configured and accessible.

## Your Task

Verify the following about the skills in this repository:

1. **List all skill directories**: Find all top-level directories that contain skills (debug-workflow, mcp-gateway, skill-creator)

2. **Verify SKILL.md exists**: For each skill directory, check that a SKILL.md file exists

3. **Validate skill configuration**: Use the quick_validate.py script to validate each skill's SKILL.md file
   - Run: `python skill-creator/scripts/quick_validate.py <skill-directory>`
   - Check if validation passes for each skill

4. **Count Python scripts**: For each skill directory with a scripts/ folder, count how many Python scripts exist

5. **Verify packaged skills**: Check the dist/ directory and verify that packaged .skill files exist for each skill

## Expected Skills

The repository should contain these skills:
- **debug-workflow**: Tools for debugging GitHub Agentic Workflow runs
- **mcp-gateway**: Tools for managing MCP Gateway with GitHub MCP servers
- **skill-creator**: Tools for creating and managing skills

## Report Format

Create a comprehensive report that includes:

### Summary
- Total number of skills found
- Number of skills passing validation
- Number of skills failing validation
- Any missing or unexpected skills

### Details for Each Skill
For each skill found, report:
- Skill name
- SKILL.md exists: Yes/No
- Validation status: Pass/Fail (with error message if failed)
- Number of Python scripts in scripts/ directory
- Packaged .skill file exists in dist/: Yes/No

### Recommendations
- If any validation failures: List specific issues and suggest fixes
- If any skills are missing SKILL.md: Recommend adding them
- If any Python scripts have issues: Note which scripts need attention

## Output Requirements

If ALL skills pass validation and all expected components are present:
- Use the `noop` safe-output to report success: `{"type": "noop", "message": "✅ All skills smoke test passed: X skills validated successfully"}`

If ANY issues are found:
- Create an issue with your detailed report using the `create_issue` safe-output
- Include the summary, details, and recommendations sections
- Use this format:
  ```json
  {
    "type": "create_issue",
    "title": "Skills Smoke Test Failed - [Brief description of issues]",
    "body": "[Your detailed markdown report here]"
  }
  ```

**IMPORTANT**: Make your report actionable. Include specific file paths, error messages, and clear next steps to resolve any issues found.
