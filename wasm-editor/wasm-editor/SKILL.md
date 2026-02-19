---
name: wasm-editor
description: "Develop and modify the gh-aw Playground (WASM editor) — the browser-based workflow compiler at docs/public/editor/. Use when: (1) Editing editor HTML/CSS/JS in docs/public/editor/, (2) Modifying WASM compiler loader/worker in docs/public/wasm/, (3) Changing the Go WASM entry point cmd/gh-aw-wasm/main.go, (4) Any task touching the playground UI, (5) Creating a PR that includes editor changes. ALWAYS verify changes visually with Playwright screenshots and attach screenshots to PRs."
---

# gh-aw Playground (WASM Editor)

Browser-based workflow compiler at https://github.github.com/gh-aw/editor/index.html. Lets users write agentic workflow markdown and see compiled GitHub Actions YAML in real-time via a Go→WASM compiler.

## Key Files

| File | Purpose |
|------|---------|
| `docs/public/editor/index.html` | Editor page — HTML, CSS, and inline `<script>` with all UI logic |
| `docs/public/editor/editor.js` | Alternate/extended editor JS (file tabs, copy button, imports) |
| `docs/public/wasm/compiler-loader.js` | ES module: spawns Web Worker, exposes `compile()` API |
| `docs/public/wasm/compiler-worker.js` | Web Worker: loads `wasm_exec.js` + `gh-aw.wasm`, handles messages |
| `docs/public/wasm/gh-aw.wasm` | Compiled WASM binary (~17 MB) |
| `docs/public/wasm/wasm_exec.js` | Go runtime JS glue |
| `cmd/gh-aw-wasm/main.go` | Go WASM entry point — exposes `compileWorkflow` to JS |

## Architecture

```
Browser ──▶ editor/index.html (UI + textarea)
               │
               ▼
         compiler-loader.js  (ES module, main thread)
               │ postMessage
               ▼
         compiler-worker.js  (Web Worker)
               │ importScripts('wasm_exec.js')
               │ fetch('gh-aw.wasm')
               ▼
         Go WASM runtime
               │ compileWorkflow(markdown, files?)
               ▼
         pkg/workflow/compiler  ──▶  YAML output
```

## Development Workflow

### 1. Start the docs dev server

```bash
cd docs && npm run dev
```

Editor is at http://localhost:4321/gh-aw/editor/

### 2. Make changes

- **UI changes**: Edit `docs/public/editor/index.html` (uses Primer CSS, no build step)
- **Compiler JS**: Edit files in `docs/public/wasm/`
- **Go compiler logic**: Edit `cmd/gh-aw-wasm/main.go` or `pkg/workflow/`, then rebuild WASM:
  ```bash
  GOOS=js GOARCH=wasm go build -o docs/public/wasm/gh-aw.wasm ./cmd/gh-aw-wasm/
  ```

### 3. Verify visually with Playwright (MANDATORY)

After every change, take a screenshot to confirm the editor renders correctly.

**Using the bundled script:**

```bash
# Ensure dev server is running, then:
python3 ~/.claude/skills/wasm-editor/wasm-editor/scripts/verify_editor.py \
  --output editor-screenshot.png
```

**Or inline with Playwright directly:**

```bash
cd docs && npx playwright test --grep "editor" 2>/dev/null || true
```

**Or write a quick Playwright check:**

```typescript
import { test, expect } from '@playwright/test';

test('editor loads and compiles', async ({ page }) => {
  await page.goto('/gh-aw/editor/');
  await page.waitForSelector('#statusText:has-text("Ready")', { timeout: 30000 });
  // Verify the status badge shows Ready (WASM loaded)
  await expect(page.locator('#statusText')).toHaveText('Ready');
  // Verify compiled output appeared
  await expect(page.locator('#outputPre')).toBeVisible();
  await page.screenshot({ path: 'test-results/editor-verified.png' });
});
```

**What to verify in screenshots:**
- Loading overlay disappears, status badge shows "Ready" (green)
- Left panel has the markdown editor with line numbers
- Right panel shows compiled YAML output
- No error banners visible
- Header bar with "gh-aw Playground" title, auto-compile toggle, compile button

### 4. Upload screenshot to PR (MANDATORY for editor PRs)

When creating a PR that touches any editor file, always attach a screenshot:

```bash
# Take the screenshot
python3 ~/.claude/skills/wasm-editor/wasm-editor/scripts/verify_editor.py \
  --output /tmp/editor-screenshot.png

# Upload to the PR body or as a comment
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
## Editor Screenshot

Visual verification of editor changes:

![Editor Screenshot](/tmp/editor-screenshot.png)

- Status: Ready (WASM loaded)
- Compilation: Working
- UI: Renders correctly
EOF
)"
```

For `gh pr create`, include the screenshot path in the PR body so reviewers can visually inspect.

**Alternative — upload as an issue comment image:**

```bash
# GitHub CLI supports uploading images in comments
# Take screenshot, then reference it
python3 ~/.claude/skills/wasm-editor/wasm-editor/scripts/verify_editor.py -o /tmp/editor.png
# The image must be uploaded via GitHub's asset upload or referenced from a URL
```

## Existing Playwright Setup

The docs site already has Playwright configured:
- Config: `docs/playwright.config.ts`
- Tests: `docs/tests/*.spec.ts`
- Base URL: `http://localhost:4321`
- Browser: Chromium (headless)
- Dev server auto-starts via `npm run dev`

Run existing tests: `cd docs && npx playwright test`

## UI Details

- **Styling**: Primer CSS (from unpkg CDN) + minimal custom CSS in `<style>` block
- **Theme**: Light/dark toggle using Primer `data-color-mode` attribute, persisted in localStorage
- **Auto-compile**: Debounced 400ms after input, toggleable
- **Keyboard**: Tab inserts 2 spaces, Ctrl/Cmd+Enter compiles
- **Panels**: Draggable divider between editor and output (touch-supported)
- **Status**: Loading → Ready → Compiling → Ready/Error (Primer Label badges)
- **Responsive**: Stacks vertically on mobile (<768px)
