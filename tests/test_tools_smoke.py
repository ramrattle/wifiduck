from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "tools" / "open_pcap_analysis.py"
INPUT_PCAP = REPO_ROOT / "sample-data" / "pcap" / "wpa-induction.pcap"
PYTHON = REPO_ROOT / ".venv" / "bin" / "python"


class ToolSmokeTests(unittest.TestCase):
    def test_helper_script_runs_with_repository_relative_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / "packets.jsonl"
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--input",
                    str(INPUT_PCAP),
                    "--output",
                    str(output),
                ]
                if not PYTHON.exists()
                else [
                    str(PYTHON),
                    str(SCRIPT),
                    "--input",
                    str(INPUT_PCAP),
                    "--output",
                    str(output),
                ],
                capture_output=True,
                text=True,
                cwd=str(REPO_ROOT),
            )

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertTrue(output.exists())
