from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class WorkflowAssetTests(unittest.TestCase):
    def test_case_pack_files_exist(self) -> None:
        expected_files = [
            REPO_ROOT / "cases" / "roam-blackhole" / "README.md",
            REPO_ROOT / "cases" / "roam-blackhole" / "playbook.sql",
            REPO_ROOT / "cases" / "retry-loop" / "README.md",
            REPO_ROOT / "cases" / "retry-loop" / "playbook.sql",
            REPO_ROOT / "cases" / "wifi7-mlo-auth-loop" / "README.md",
            REPO_ROOT / "cases" / "wifi7-mlo-auth-loop" / "playbook.sql",
            REPO_ROOT / "examples" / "sql" / "staged_triage.sql",
        ]

        for path in expected_files:
            self.assertTrue(path.exists(), f"Missing workflow asset: {path}")

    def test_staged_triage_playbook_spells_out_workflow(self) -> None:
        text = (REPO_ROOT / "examples" / "sql" / "staged_triage.sql").read_text(encoding="utf-8")

        self.assertIn("Stage 1: triage", text)
        self.assertIn("Stage 2: isolate", text)
        self.assertIn("Stage 3: prove", text)
        self.assertIn("Stage 4: explain", text)
