from pathlib import Path
import unittest

import duckdb


REPO_ROOT = Path(__file__).resolve().parents[1]
WPA_FIXTURE = REPO_ROOT / "sample-data" / "jsonl" / "wpa_induction_fixture.jsonl"


def load_sql_modules() -> str:
    sql_files = [
        REPO_ROOT / "sql" / "core" / "wifi_packets.sql",
        REPO_ROOT / "sql" / "macros" / "retries.sql",
        REPO_ROOT / "sql" / "macros" / "disconnects.sql",
        REPO_ROOT / "sql" / "macros" / "channels.sql",
        REPO_ROOT / "sql" / "macros" / "roaming.sql",
        REPO_ROOT / "sql" / "macros" / "dhcp_dns.sql",
        REPO_ROOT / "sql" / "macros" / "client_experience.sql",
        REPO_ROOT / "sql" / "macros" / "handshakes.sql",
        REPO_ROOT / "sql" / "macros" / "wifi7.sql",
    ]
    return "\n\n".join(path.read_text(encoding="utf-8") for path in sql_files)


class SqlMacroTests(unittest.TestCase):
    def setUp(self) -> None:
        self.con = duckdb.connect(database=":memory:")
        self.con.execute(load_sql_modules())

    def tearDown(self) -> None:
        self.con.close()

    def test_retry_hotspots_jsonl_reports_retry_counts(self) -> None:
        rows = self.con.execute(
            """
            SELECT tx_addr, total_frames, retry_frames, retry_pct
            FROM wd_retry_hotspots_jsonl(?, 5)
            ORDER BY retry_pct DESC, total_frames DESC
            """,
            [str(WPA_FIXTURE)],
        ).fetchall()

        self.assertEqual(rows[0][0], "aa:aa:aa:aa:aa:aa")
        self.assertEqual(rows[0][1], 3)
        self.assertEqual(rows[0][2], 2)
        self.assertEqual(rows[0][3], 66.67)

    def test_disconnect_reasons_jsonl_reports_reason_distribution(self) -> None:
        rows = self.con.execute(
            """
            SELECT reason_code, frame_count
            FROM wd_disconnect_reasons_jsonl(?, 10)
            ORDER BY frame_count DESC, reason_code ASC
            """,
            [str(WPA_FIXTURE)],
        ).fetchall()

        self.assertEqual(rows[0], (4, 2))

    def test_channel_health_jsonl_summarizes_per_channel_metrics(self) -> None:
        rows = self.con.execute(
            """
            SELECT channel_freq_mhz, frames, retry_pct
            FROM wd_channel_health_jsonl(?, 10)
            ORDER BY frames DESC, retry_pct DESC
            """,
            [str(WPA_FIXTURE)],
        ).fetchall()

        self.assertEqual(rows[0], (5180, 11, 18.18))

    def test_roaming_events_jsonl_finds_management_activity(self) -> None:
        rows = self.con.execute(
            """
            SELECT tx_addr, subtype, events
            FROM wd_roaming_events_jsonl(?, 10)
            WHERE tx_addr = 'cc:cc:cc:cc:cc:cc'
            """,
            [str(WPA_FIXTURE)],
        ).fetchall()

        self.assertEqual(rows[0], ("cc:cc:cc:cc:cc:cc", 2, 2))

    def test_dns_dhcp_gaps_jsonl_calculates_latency_gap(self) -> None:
        row = self.con.execute(
            """
            SELECT tx_addr, dhcp_packets, dns_packets, dhcp_to_dns_ms
            FROM wd_dns_dhcp_gaps_jsonl(?, 10)
            WHERE tx_addr = 'bb:bb:bb:bb:bb:bb'
            """,
            [str(WPA_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("bb:bb:bb:bb:bb:bb", 1, 1, 500))

    def test_roam_health_jsonl_flags_reassociation_churn(self) -> None:
        row = self.con.execute(
            """
            SELECT tx_addr, roam_event_count, roam_window_ms, status
            FROM wd_roam_health_jsonl(?, 10)
            WHERE tx_addr = 'cc:cc:cc:cc:cc:cc'
            """,
            [str(WPA_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("cc:cc:cc:cc:cc:cc", 2, 1000, "unstable"))

    def test_post_roam_blackhole_jsonl_flags_missing_l3_after_reassoc(self) -> None:
        row = self.con.execute(
            """
            SELECT tx_addr, roam_ts, first_dhcp_or_dns_ts, l3_gap_ms, status
            FROM wd_post_roam_blackhole_jsonl(?, 10)
            WHERE tx_addr = 'cc:cc:cc:cc:cc:cc'
            """,
            [str(WPA_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("cc:cc:cc:cc:cc:cc", 21.0, None, None, "suspected_blackhole"))

    def test_auth_assoc_loops_jsonl_flags_excessive_pre_assoc_frames(self) -> None:
        row = self.con.execute(
            """
            SELECT tx_addr, auth_frames, assoc_request_frames, handshake_attempt_frames, status
            FROM wd_auth_assoc_loops_jsonl(?, 10)
            WHERE tx_addr = 'ee:ee:ee:ee:ee:ee'
            """,
            [str(WPA_FIXTURE)],
        ).fetchone()

        self.assertEqual(row, ("ee:ee:ee:ee:ee:ee", 3, 1, 4, "retry_loop"))
