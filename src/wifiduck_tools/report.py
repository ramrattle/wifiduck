from __future__ import annotations

import argparse
from pathlib import Path
import sys

import duckdb


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def load_sql_modules(root: Path) -> str:
    sql_files = [
        root / "sql" / "core" / "wifi_packets.sql",
        root / "sql" / "core" / "classified_packets.sql",
        root / "sql" / "macros" / "retries.sql",
        root / "sql" / "macros" / "disconnects.sql",
        root / "sql" / "macros" / "channels.sql",
        root / "sql" / "macros" / "roaming.sql",
        root / "sql" / "macros" / "dhcp_dns.sql",
        root / "sql" / "macros" / "client_experience.sql",
        root / "sql" / "macros" / "handshakes.sql",
        root / "sql" / "macros" / "packet_classes.sql",
        root / "sql" / "macros" / "sessions.sql",
        root / "sql" / "macros" / "reports.sql",
        root / "sql" / "macros" / "wifi7.sql",
    ]
    return "\n\n".join(path.read_text(encoding="utf-8") for path in sql_files)


def fetch_rows(con: duckdb.DuckDBPyConnection, query: str, params: list[str]) -> list[dict[str, object]]:
    result = con.execute(query, params)
    columns = [column[0] for column in result.description]
    return [dict(zip(columns, row)) for row in result.fetchall()]


def collect_report_data(input_path: Path, input_format: str) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    root = repo_root()
    con = duckdb.connect(database=":memory:")
    try:
        con.execute(load_sql_modules(root))
        report_macro = "wd_capture_report_jsonl" if input_format == "jsonl" else "wd_capture_report"
        sessions_macro = "wd_connection_sessions_jsonl" if input_format == "jsonl" else "wd_connection_sessions"
        missing_links_macro = "wd_wifi7_missing_links_jsonl" if input_format == "jsonl" else "wd_wifi7_missing_links"
        link_health_macro = "wd_wifi7_link_health_jsonl" if input_format == "jsonl" else "wd_wifi7_link_health"

        findings = fetch_rows(
            con,
            f"SELECT issue_type, subject_addr, peer_addr, severity, status, summary, next_step FROM {report_macro}(?, 20)",
            [str(input_path)],
        )
        journeys = fetch_rows(
            con,
            f"SELECT subject_addr, peer_addr, session_kind, status, summary FROM {sessions_macro}(?, 20)",
            [str(input_path)],
        )
        missing_links = fetch_rows(
            con,
            f"SELECT mld_mac_addr, expected_links, active_links, status FROM {missing_links_macro}(?, 20)",
            [str(input_path)],
        )
        link_health = fetch_rows(
            con,
            f"SELECT mld_mac_addr, weakest_link_id, strongest_link_id, rssi_gap_db, imbalance_status FROM {link_health_macro}(?, 20)",
            [str(input_path)],
        )
    finally:
        con.close()

    wifi7_rows: list[dict[str, object]] = []
    seen_status = set()
    for row in missing_links:
        status = str(row["status"])
        summary = (
            f"expected_links={row['expected_links']}, active_links={row['active_links']}"
            if status == "partial_activation"
            else f"All advertised links showed join-progress visibility ({row['active_links']}/{row['expected_links']})."
        )
        wifi7_row = {
            "mld_mac_addr": row["mld_mac_addr"],
            "status": status,
            "summary": summary,
        }
        wifi7_rows.append(wifi7_row)
        seen_status.add((row["mld_mac_addr"], status))

    for row in link_health:
        status = str(row["imbalance_status"])
        key = (row["mld_mac_addr"], status)
        if key in seen_status:
            continue
        wifi7_rows.append(
            {
                "mld_mac_addr": row["mld_mac_addr"],
                "status": status,
                "summary": (
                    f"weakest_link={row['weakest_link_id']}, strongest_link={row['strongest_link_id']}, "
                    f"rssi_gap_db={row['rssi_gap_db']}"
                ),
            }
        )
    return findings, journeys, wifi7_rows


def render_markdown(
    summary_rows: list[dict[str, object]],
    journey_rows: list[dict[str, object]],
    wifi7_rows: list[dict[str, object]],
) -> str:
    lines = [
        "# Executive Summary",
        "",
        f"- Top finding count: {len(summary_rows)}",
        "",
        "## Top Findings",
    ]
    if summary_rows:
        for row in summary_rows:
            lines.append(
                f"- `{row['severity']}` `{row['issue_type']}` on `{row['subject_addr']}`: {row['summary']}"
            )
    else:
        lines.append("- No ranked findings were produced for this capture.")

    lines.extend(["", "## Client Journeys"])
    if journey_rows:
        for row in journey_rows[:5]:
            lines.append(
                f"- `{row['subject_addr']}` `{row['session_kind']}` -> `{row['status']}`: {row['summary']}"
            )
    else:
        lines.append("- No client journeys were reconstructed from the available frames.")

    lines.extend(["", "## Wi-Fi 7 / MLO Observations"])
    if wifi7_rows:
        for row in wifi7_rows:
            lines.append(f"- `{row['mld_mac_addr']}` `{row['status']}`: {row['summary']}")
    else:
        lines.append("- No Wi-Fi 7 / MLO observations in this capture.")

    lines.extend(["", "## Recommended Next Checks"])
    if summary_rows:
        for row in summary_rows[:3]:
            lines.append(f"- {row['next_step']}")
    else:
        lines.append("- Capture a longer management-frame sequence or add DHCP/DNS visibility.")
    return "\n".join(lines) + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render a markdown troubleshooting report from a capture.")
    parser.add_argument("--input", required=True)
    parser.add_argument("--format", choices=["jsonl", "pcap"], default="jsonl")
    parser.add_argument("--output")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    input_path = Path(args.input).resolve()
    findings, journeys, wifi7_rows = collect_report_data(input_path, args.format)
    markdown = render_markdown(findings, journeys, wifi7_rows)
    if args.output:
        Path(args.output).write_text(markdown, encoding="utf-8")
    else:
        sys.stdout.write(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
