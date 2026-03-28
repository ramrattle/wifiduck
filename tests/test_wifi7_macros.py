from pathlib import Path
import unittest

import duckdb


REPO_ROOT = Path(__file__).resolve().parents[1]
WIFI7_FIXTURE = REPO_ROOT / "sample-data" / "jsonl" / "wifi7_mlo_fixture.jsonl"


def load_sql_modules() -> str:
    sql_files = [
        REPO_ROOT / "sql" / "core" / "wifi_packets.sql",
        REPO_ROOT / "sql" / "core" / "classified_packets.sql",
        REPO_ROOT / "sql" / "macros" / "retries.sql",
        REPO_ROOT / "sql" / "macros" / "disconnects.sql",
        REPO_ROOT / "sql" / "macros" / "channels.sql",
        REPO_ROOT / "sql" / "macros" / "roaming.sql",
        REPO_ROOT / "sql" / "macros" / "dhcp_dns.sql",
        REPO_ROOT / "sql" / "macros" / "client_experience.sql",
        REPO_ROOT / "sql" / "macros" / "handshakes.sql",
        REPO_ROOT / "sql" / "macros" / "packet_classes.sql",
        REPO_ROOT / "sql" / "macros" / "sessions.sql",
        REPO_ROOT / "sql" / "macros" / "reports.sql",
        REPO_ROOT / "sql" / "macros" / "wifi7.sql",
    ]
    return "\n\n".join(path.read_text(encoding="utf-8") for path in sql_files)


class Wifi7MacroTests(unittest.TestCase):
    def setUp(self) -> None:
        self.con = duckdb.connect(database=":memory:")
        self.con.execute(load_sql_modules())

    def tearDown(self) -> None:
        self.con.close()

    def test_mlo_overview_jsonl_reports_mld_activity(self) -> None:
        row = self.con.execute(
            """
            SELECT mld_mac_addr, frame_count, distinct_link_ids, sta_profile_count
            FROM wd_mlo_overview_jsonl(?, 10)
            WHERE mld_mac_addr = '22:22:22:22:22:22'
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(
            row,
            ("22:22:22:22:22:22", 2, 2, 2),
        )

    def test_wifi7_capabilities_jsonl_flags_6ghz_presence(self) -> None:
        row = self.con.execute(
            """
            SELECT six_ghz_frames, wide_channel_frames, mld_id_present_frames
            FROM wd_wifi7_capabilities_jsonl(?, 10)
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, (9, 9, 9))

    def test_wifi7_auth_assoc_loops_jsonl_highlights_first_attempt_failure_pattern(self) -> None:
        row = self.con.execute(
            """
            SELECT tx_addr, auth_frames, assoc_request_frames, handshake_attempt_frames, status
            FROM wd_auth_assoc_loops_jsonl(?, 10)
            WHERE tx_addr = 'a2:02:a5:e0:54:5f'
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("a2:02:a5:e0:54:5f", 3, 1, 4, "retry_loop"))

    def test_wifi7_capture_report_jsonl_flags_mlo_retry_loop(self) -> None:
        row = self.con.execute(
            """
            SELECT issue_type, subject_addr, severity, summary
            FROM wd_capture_report_jsonl(?, 10)
            WHERE issue_type = 'auth_assoc_loop'
              AND subject_addr = 'a2:02:a5:e0:54:5f'
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(
            row,
            (
                "auth_assoc_loop",
                "a2:02:a5:e0:54:5f",
                "high",
                "Authentication repeated three times before the first association request.",
            ),
        )

    def test_wifi7_link_health_jsonl_flags_imbalance(self) -> None:
        row = self.con.execute(
            """
            SELECT mld_mac_addr, weakest_link_id, strongest_link_id, imbalance_status
            FROM wd_wifi7_link_health_jsonl(?, 10)
            WHERE mld_mac_addr = '44:44:44:44:44:44'
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("44:44:44:44:44:44", 2, 1, "imbalanced"))

    def test_wifi7_missing_links_jsonl_flags_partial_activation(self) -> None:
        row = self.con.execute(
            """
            SELECT mld_mac_addr, expected_links, active_links, status
            FROM wd_wifi7_missing_links_jsonl(?, 10)
            WHERE mld_mac_addr = '44:44:44:44:44:44'
            """,
            [str(WIFI7_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("44:44:44:44:44:44", 2, 1, "partial_activation"))
