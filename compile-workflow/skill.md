# Compile Workflow

Compiles a gh-aw markdown workflow into a GitHub Actions YAML file.

## When to Use

- When user asks to compile a workflow
- When user creates or modifies a `.md` workflow file
- When user wants to see the generated GitHub Actions YAML
- After making changes to workflow markdown files

## Prerequisites

- The `gh-aw` binary must be built (run `make build` if needed)
- Workflow file must exist in `.github/workflows/` or `.github/aw/`
- Workflow must be a standalone workflow (has `on:` trigger), not a shared component

## Steps

1. Verify the workflow file exists and is a valid markdown file
2. Build gh-aw if not already built: `make build`
3. Run compilation: `./gh-aw compile <workflow-file>.md`
4. Check for compilation errors and report them to the user
5. If successful, the `.lock.yml` file will be generated alongside the `.md` file
6. Display the location of the generated file

## Examples

### Compiling a single workflow
```bash
make build
./gh-aw compile .github/workflows/my-workflow.md
```

### Recompiling all workflows (after compiler changes)
```bash
make recompile
```

## Common Issues

- **Workflow cannot be compiled**: Check if it's a shared component (located in `.github/workflows/shared/`). Shared components cannot be compiled directly.
- **Build errors**: Run `make build` first to ensure the compiler is up to date
- **Syntax errors**: Check the markdown frontmatter and structure

## Related Commands

- `make watch` - Auto-compile on file changes during development
- `make recompile` - Recompile all workflows at once
