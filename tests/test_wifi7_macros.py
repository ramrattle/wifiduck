from pathlib import Path
import unittest

import duckdb


REPO_ROOT = Path(__file__).resolve().parents[1]
WIFI7_FIXTURE = REPO_ROOT / "sample-data" / "jsonl" / "wifi7_mlo_fixture.jsonl"


def load_sql_modules() -> str:
    sql_files = [
        REPO_ROOT / "sql" / "core" / "wifi_packets.sql",
        REPO_ROOT / "sql" / "macros" / "retries.sql",
        REPO_ROOT / "sql" / "macros" / "disconnects.sql",
        REPO_ROOT / "sql" / "macros" / "channels.sql",
        REPO_ROOT / "sql" / "macros" / "roaming.sql",
        REPO_ROOT / "sql" / "macros" / "dhcp_dns.sql",
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

        self.assertEqual(row, (2, 2, 2))
