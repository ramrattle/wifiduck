from pathlib import Path
import subprocess
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
WPA_FIXTURE = REPO_ROOT / "sample-data" / "jsonl" / "wpa_induction_fixture.jsonl"


class ReportCliTests(unittest.TestCase):
    def test_markdown_report_renders_core_sections(self) -> None:
        result = subprocess.run(
            [
                str(REPO_ROOT / ".venv" / "bin" / "python"),
                "-m",
                "wifiduck_tools.report",
                "--input",
                str(WPA_FIXTURE),
                "--format",
                "jsonl",
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("# Executive Summary", result.stdout)
        self.assertIn("## Top Findings", result.stdout)
        self.assertIn("## Client Journeys", result.stdout)

