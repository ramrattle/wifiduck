from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class ReadmeAssetTests(unittest.TestCase):
    def test_readme_references_hero_banner(self) -> None:
        readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("![wifiduck hero]", readme)
        self.assertIn("docs/assets/hero-banner.svg", readme)
