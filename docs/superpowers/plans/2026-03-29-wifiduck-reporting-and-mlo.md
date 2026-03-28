# Wifiduck Reporting And MLO Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a markdown incident-report CLI and deeper Wi-Fi 7 / MLO link analytics while keeping SQL as the source of truth.

**Architecture:** Extend the SQL pack with Wi-Fi 7 link-health, transition, and missing-link macros plus a report-assembly layer. Keep Python thin: one module loads DuckDB, executes the report queries, and renders stable markdown sections from SQL rows.

**Tech Stack:** DuckDB SQL, Python 3, unittest, argparse

---

### Task 1: Add failing tests for Wi-Fi 7 link analytics

**Files:**
- Modify: `tests/test_wifi7_macros.py`
- Modify: `sample-data/jsonl/wifi7_mlo_fixture.jsonl`
- Test: `tests/test_wifi7_macros.py`

- [ ] **Step 1: Write the failing tests**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./.venv/bin/python -m unittest tests.test_wifi7_macros -v`
Expected: `Catalog Error` or `FileNotFoundError` because `wd_wifi7_link_health_jsonl` and `wd_wifi7_missing_links_jsonl` do not exist yet.

- [ ] **Step 3: Extend the Wi-Fi 7 fixture minimally**

```json
{"ts": 102.07, "packet_num": 10, "tx_addr": "a2:02:a5:e0:54:5f", "rx_addr": "ec:f4:0c:9d:6b:e9", "subtype": 2, "retry_flag": 0, "reason_code": null, "channel_freq_mhz": 6215, "rssi_dbm": -66.0, "dns_query": null, "dhcp_hostname": null, "mld_mac_addr": "44:44:44:44:44:44", "link_id": 2, "eht_sta_profile_count": 2, "mld_id_present": 1, "channel_width_mhz": 160, "is_6ghz": 1}
```

- [ ] **Step 4: Commit**

```bash
git add tests/test_wifi7_macros.py sample-data/jsonl/wifi7_mlo_fixture.jsonl
git commit -m "test: add Wi-Fi 7 link analytics coverage"
```

### Task 2: Implement Wi-Fi 7 link-health, transition, and missing-link macros

**Files:**
- Modify: `sql/macros/wifi7.sql`
- Modify: `sql/wifiduck.sql`
- Test: `tests/test_wifi7_macros.py`

- [ ] **Step 1: Write the minimal SQL macros**

```sql
CREATE OR REPLACE MACRO wd_wifi7_link_health_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    link_id,
    COUNT(*) AS frames,
    AVG(rssi_dbm) AS avg_rssi_dbm,
    MAX(channel_width_mhz) AS channel_width_mhz
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE mld_mac_addr IS NOT NULL
    AND link_id IS NOT NULL
  GROUP BY mld_mac_addr, link_id
), ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY mld_mac_addr ORDER BY avg_rssi_dbm DESC, frames DESC, link_id ASC) AS best_rank,
    ROW_NUMBER() OVER (PARTITION BY mld_mac_addr ORDER BY avg_rssi_dbm ASC, frames ASC, link_id ASC) AS weak_rank
  FROM base
)
SELECT
  strong.mld_mac_addr,
  weak.link_id AS weakest_link_id,
  strong.link_id AS strongest_link_id,
  ROUND(strong.avg_rssi_dbm - weak.avg_rssi_dbm, 2) AS rssi_gap_db,
  CASE
    WHEN strong.avg_rssi_dbm - weak.avg_rssi_dbm >= 10 THEN 'imbalanced'
    ELSE 'balanced'
  END AS imbalance_status
FROM ranked strong
JOIN ranked weak
  ON strong.mld_mac_addr = weak.mld_mac_addr
WHERE strong.best_rank = 1
  AND weak.weak_rank = 1
ORDER BY rssi_gap_db DESC, strong.mld_mac_addr ASC
LIMIT top_n;
```

- [ ] **Step 2: Add transition and missing-link macros in the same file**

```sql
CREATE OR REPLACE MACRO wd_wifi7_link_transitions_jsonl(jsonl_file, top_n) AS TABLE
SELECT
  mld_mac_addr,
  tx_addr AS subject_addr,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen,
  COUNT(DISTINCT link_id) AS observed_links,
  string_agg(CAST(link_id AS VARCHAR), '->' ORDER BY ts, packet_num) AS link_timeline
FROM wd_wifi_packets_jsonl(jsonl_file)
WHERE mld_mac_addr IS NOT NULL
  AND link_id IS NOT NULL
GROUP BY mld_mac_addr, tx_addr
ORDER BY last_seen DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_missing_links_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    MAX(COALESCE(eht_sta_profile_count, 0)) AS expected_links,
    COUNT(DISTINCT link_id) AS active_links
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE mld_mac_addr IS NOT NULL
  GROUP BY mld_mac_addr
)
SELECT
  mld_mac_addr,
  expected_links,
  active_links,
  CASE
    WHEN expected_links > active_links THEN 'partial_activation'
    ELSE 'fully_visible'
  END AS status
FROM base
ORDER BY expected_links DESC, mld_mac_addr ASC
LIMIT top_n;
```

- [ ] **Step 3: Mirror the macros for PCAP input and load them**

Run: edit `sql/macros/wifi7.sql` to add `wd_wifi7_link_health`, `wd_wifi7_link_transitions`, and `wd_wifi7_missing_links`, then ensure `sql/wifiduck.sql` still loads the same Wi-Fi 7 module.
Expected: no loader changes beyond preserving the `.read sql/macros/wifi7.sql` line.

- [ ] **Step 4: Run test to verify it passes**

Run: `./.venv/bin/python -m unittest tests.test_wifi7_macros -v`
Expected: PASS for the new Wi-Fi 7 tests and existing Wi-Fi 7 coverage.

- [ ] **Step 5: Commit**

```bash
git add sql/macros/wifi7.sql sql/wifiduck.sql tests/test_wifi7_macros.py sample-data/jsonl/wifi7_mlo_fixture.jsonl
git commit -m "feat: add Wi-Fi 7 link analytics"
```

### Task 3: Add failing tests for markdown incident reporting

**Files:**
- Create: `tests/test_report_cli.py`
- Modify: `pyproject.toml`
- Test: `tests/test_report_cli.py`

- [ ] **Step 1: Write the failing CLI tests**

```python
def test_markdown_report_renders_core_sections() -> None:
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

    assert result.returncode == 0
    assert "# Executive Summary" in result.stdout
    assert "## Top Findings" in result.stdout
    assert "## Client Journeys" in result.stdout
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./.venv/bin/python -m unittest tests.test_report_cli -v`
Expected: FAIL because `wifiduck_tools.report` does not exist yet.

- [ ] **Step 3: Add the CLI entry point placeholder to packaging**

```toml
[project.scripts]
wifiduck-report = "wifiduck_tools.report:main"
```

- [ ] **Step 4: Commit**

```bash
git add tests/test_report_cli.py pyproject.toml
git commit -m "test: add markdown report CLI coverage"
```

### Task 4: Implement SQL-backed markdown report rendering

**Files:**
- Create: `src/wifiduck_tools/report.py`
- Modify: `src/wifiduck_tools/__init__.py`
- Modify: `pyproject.toml`
- Test: `tests/test_report_cli.py`

- [ ] **Step 1: Implement the DuckDB loader and query helpers**

```python
def load_sql_modules(repo_root: Path) -> str:
    sql_files = [
        repo_root / "sql" / "core" / "wifi_packets.sql",
        repo_root / "sql" / "core" / "classified_packets.sql",
        repo_root / "sql" / "macros" / "retries.sql",
        repo_root / "sql" / "macros" / "disconnects.sql",
        repo_root / "sql" / "macros" / "channels.sql",
        repo_root / "sql" / "macros" / "roaming.sql",
        repo_root / "sql" / "macros" / "dhcp_dns.sql",
        repo_root / "sql" / "macros" / "client_experience.sql",
        repo_root / "sql" / "macros" / "handshakes.sql",
        repo_root / "sql" / "macros" / "packet_classes.sql",
        repo_root / "sql" / "macros" / "sessions.sql",
        repo_root / "sql" / "macros" / "reports.sql",
        repo_root / "sql" / "macros" / "wifi7.sql",
    ]
    return "\n\n".join(path.read_text(encoding="utf-8") for path in sql_files)
```

- [ ] **Step 2: Implement markdown rendering with stable sections**

```python
def render_markdown(summary_rows, journey_rows, wifi7_rows) -> str:
    lines = [
        "# Executive Summary",
        "",
        f"- Top finding count: {len(summary_rows)}",
        "",
        "## Top Findings",
    ]
    for row in summary_rows:
        lines.append(f"- `{row['severity']}` `{row['issue_type']}` on `{row['subject_addr']}`: {row['summary']}")
    lines.extend(["", "## Client Journeys"])
    for row in journey_rows:
        lines.append(f"- `{row['subject_addr']}` `{row['session_kind']}` -> `{row['status']}`: {row['summary']}")
    lines.extend(["", "## Wi-Fi 7 / MLO Observations"])
    if wifi7_rows:
        for row in wifi7_rows:
            lines.append(f"- `{row['mld_mac_addr']}`: {row['status']}")
    else:
        lines.append("- No Wi-Fi 7 / MLO observations in this capture.")
    lines.extend(["", "## Recommended Next Checks"])
    for row in summary_rows[:3]:
        lines.append(f"- {row['next_step']}")
    return "\n".join(lines) + "\n"
```

- [ ] **Step 3: Wire `main()` to accept JSONL or PCAP input**

```python
parser.add_argument("--input", required=True)
parser.add_argument("--format", choices=["jsonl", "pcap"], default="jsonl")
parser.add_argument("--output")
```

Run: `./.venv/bin/python -m unittest tests.test_report_cli -v`
Expected: PASS, with the CLI producing markdown to stdout.

- [ ] **Step 4: Commit**

```bash
git add src/wifiduck_tools/report.py src/wifiduck_tools/__init__.py pyproject.toml tests/test_report_cli.py
git commit -m "feat: add markdown incident report CLI"
```

### Task 5: Add examples and docs for report generation and Wi-Fi 7 workflows

**Files:**
- Modify: `README.md`
- Modify: `docs/wifi7.md`
- Create: `examples/sql/wifi7_mlo_report.sql`
- Create: `cases/wifi7-mlo-link-imbalance/README.md`
- Create: `cases/wifi7-mlo-link-imbalance/playbook.sql`

- [ ] **Step 1: Add a Wi-Fi 7 report playbook**

```sql
-- Wi-Fi 7 report-oriented workflow
.read sql/wifiduck.sql

SELECT * FROM wd_wifi7_link_health_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
SELECT * FROM wd_wifi7_missing_links_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
SELECT * FROM wd_wifi7_link_transitions_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
```

- [ ] **Step 2: Document the CLI**

```md
python -m wifiduck_tools.report \
  --input sample-data/jsonl/wifi7_mlo_fixture.jsonl \
  --format jsonl
```

- [ ] **Step 3: Add the new case pack**

```md
Problem seen: the MLD advertises two links, but only one link carries meaningful join progress while the other remains weak or incomplete.
```

- [ ] **Step 4: Commit**

```bash
git add README.md docs/wifi7.md examples/sql/wifi7_mlo_report.sql cases/wifi7-mlo-link-imbalance
git commit -m "docs: add report and Wi-Fi 7 workflow examples"
```

### Task 6: Full verification

**Files:**
- Verify only

- [ ] **Step 1: Run the full test suite**

Run: `./.venv/bin/python -m unittest discover -s tests -v`
Expected: all tests pass.

- [ ] **Step 2: Run the report CLI on the bundled fixtures**

Run: `./.venv/bin/python -m wifiduck_tools.report --input sample-data/jsonl/wpa_induction_fixture.jsonl --format jsonl`
Expected: markdown with `# Executive Summary`, `## Top Findings`, `## Client Journeys`, `## Wi-Fi 7 / MLO Observations`, and `## Recommended Next Checks`.

- [ ] **Step 3: Run the report CLI on the Wi-Fi 7 fixture**

Run: `./.venv/bin/python -m wifiduck_tools.report --input sample-data/jsonl/wifi7_mlo_fixture.jsonl --format jsonl`
Expected: markdown that includes Wi-Fi 7 / MLO observations and at least one `partial_activation` or imbalance-style finding.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: verify reporting and MLO workflow"
```
