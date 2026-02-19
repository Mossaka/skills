#!/usr/bin/env python3
"""
Take a screenshot of the gh-aw Playground editor using Playwright.

Usage:
    python3 verify_editor.py [--output screenshot.png] [--url URL]

Requires: playwright (pip install playwright && playwright install chromium)
The docs dev server must be running (npm run dev in docs/).
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path


def ensure_playwright():
    """Check that playwright is importable; install if missing."""
    try:
        import playwright  # noqa: F401
        return True
    except ImportError:
        print("Installing playwright...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "playwright", "-q"])
        subprocess.check_call([sys.executable, "-m", "playwright", "install", "chromium"])
        return True


def take_screenshot(url: str, output: str, wait_ms: int = 5000) -> str:
    """Launch headless Chromium, navigate to the editor, and save a screenshot."""
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1280, "height": 800})
        page.goto(url, wait_until="networkidle")
        # Wait for WASM compiler to load and auto-compile
        page.wait_for_timeout(wait_ms)
        page.screenshot(path=output, full_page=False)
        browser.close()

    abs_path = str(Path(output).resolve())
    print(f"Screenshot saved: {abs_path}")
    return abs_path


def main():
    parser = argparse.ArgumentParser(description="Screenshot the gh-aw Playground editor")
    parser.add_argument("--output", "-o", default="editor-screenshot.png",
                        help="Output PNG path (default: editor-screenshot.png)")
    parser.add_argument("--url", default="http://localhost:4321/gh-aw/editor/",
                        help="Editor URL (default: http://localhost:4321/gh-aw/editor/)")
    parser.add_argument("--wait", type=int, default=5000,
                        help="Milliseconds to wait for WASM load (default: 5000)")
    args = parser.parse_args()

    ensure_playwright()
    take_screenshot(args.url, args.output, args.wait)


if __name__ == "__main__":
    main()
