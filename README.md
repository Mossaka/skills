# Agent Skills

This directory contains custom skills for agents that are available globally across all projects.

Learn more about agent skills at https://agentskills.io/home

## Structure

Each skill should be in its own directory with the following structure:

```
~/.claude/skills/
├── README.md                 # This file
├── skill-name/              # Individual skill directory
│   ├── skill.md             # Skill definition and instructions
│   └── examples/            # Optional: Example usage
```

## Creating a New Skill

1. Create a new directory for your skill: `~/.claude/skills/your-skill-name/`
2. Create a `skill.md` file with your skill definition
3. The skill.md should include:
   - Clear description of what the skill does
   - Step-by-step instructions for Claude to follow
   - Any prerequisites or requirements
   - Examples of when to use the skill

## Skill Template

```markdown
# Skill Name

Brief description of what this skill does.

## When to Use

- Condition 1
- Condition 2

## Steps

1. First step
2. Second step
3. Third step

## Examples

[Include examples of usage]
```

## Available Skills

Skills will be listed here as they are created.
