# Wifiduck Hero Banner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a polished GitHub README hero banner for `wifiduck` and wire it into the repository landing page.

**Architecture:** Generate one wide raster banner asset that matches the approved packet-forensics art direction, store it under `docs/assets/`, and keep the README change minimal by referencing that single image near the top of the page. Treat the image as a first-class repository asset rather than an external link.

**Tech Stack:** Markdown, raster image asset, GitHub README rendering

---

### Task 1: Add a failing README expectation test

**Files:**
- Create: `tests/test_readme_assets.py`
- Test: `tests/test_readme_assets.py`

- [ ] **Step 1: Write the failing test**

```python
from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class ReadmeAssetTests(unittest.TestCase):
    def test_readme_references_hero_banner(self) -> None:
        readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("![wifiduck hero]", readme)
        self.assertIn("docs/assets/hero-banner.png", readme)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./.venv/bin/python -m unittest tests.test_readme_assets -v`
Expected: FAIL because the README does not reference a hero banner yet.

- [ ] **Step 3: Commit**

```bash
git add tests/test_readme_assets.py
git commit -m "test: add README hero banner coverage"
```

### Task 2: Generate and store the hero banner asset

**Files:**
- Create: `docs/assets/hero-banner.png`

- [ ] **Step 1: Generate the banner image**

Use the approved prompt direction:

```text
Wide GitHub hero banner for a project named wifiduck, dark packet-forensics console mood, serious technical tone with witty undertone, high-contrast graphite or midnight background, electric cyan and acid green accents, left-aligned premium terminal-grade typography reading "wifiduck", subtitle "SQL-first Wi-Fi packet forensics", tagline "Sniff first. Guess later.", right side filled with abstract packet-analysis imagery, radiotap-like overlays, RF traces, MLO-inspired link geometry, subtle clever duck-shaped visual joke hidden in the signal forms, not mascot-led, not childish, clean negative space, crisp cinematic lighting, designed to stay readable when scaled down on a GitHub README, 1600x640 composition.
```

- [ ] **Step 2: Save the selected output into the repository**

Target path: `docs/assets/hero-banner.png`

- [ ] **Step 3: Verify the file exists**

Run: `ls docs/assets/hero-banner.png`
Expected: the file path prints with exit code `0`.

- [ ] **Step 4: Commit**

```bash
git add docs/assets/hero-banner.png
git commit -m "feat: add README hero banner asset"
```

### Task 3: Wire the banner into the README

**Files:**
- Modify: `README.md`
- Test: `tests/test_readme_assets.py`

- [ ] **Step 1: Add the hero banner near the top of the README**

```md
# Wifiduck

![wifiduck hero](docs/assets/hero-banner.png)
```

- [ ] **Step 2: Keep the rest of the README intact**

Expected change: the banner appears immediately under the top-level heading and before the project description paragraph.

- [ ] **Step 3: Run the README asset test**

Run: `./.venv/bin/python -m unittest tests.test_readme_assets -v`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add README.md tests/test_readme_assets.py
git commit -m "docs: add hero banner to README"
```

### Task 4: Final verification

**Files:**
- Verify only

- [ ] **Step 1: Run the focused README test**

Run: `./.venv/bin/python -m unittest tests.test_readme_assets -v`
Expected: PASS.

- [ ] **Step 2: Run the full test suite**

Run: `./.venv/bin/python -m unittest discover -s tests -v`
Expected: all tests pass.

- [ ] **Step 3: Inspect git status**

Run: `git status --short`
Expected: clean working tree after commits.

- [ ] **Step 4: Commit if verification requires any final adjustment**

```bash
git add -A
git commit -m "test: verify README hero banner integration"
```
