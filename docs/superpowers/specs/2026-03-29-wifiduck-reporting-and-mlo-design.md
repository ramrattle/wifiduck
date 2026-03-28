# Wifiduck Reporting And MLO Design

## Goal
Add a serious incident-style workflow to `wifiduck` without moving logic out of SQL. The next phase should make capture results easier to read, easier to demo, and more useful for Wi-Fi 7 / MLO troubleshooting.

## Product Direction
`wifiduck` stays SQL-first. Detection, scoring, and Wi-Fi reasoning remain in DuckDB macros. Python is used only as a thin execution and rendering layer that turns SQL output into a markdown report.

## Scope
- Add markdown incident reporting driven by SQL findings.
- Add deeper Wi-Fi 7 / MLO analytics for link health, imbalance, transitions, and missing-link detection.
- Keep new features compatible with both `wireduck` PCAP reads and JSONL fixtures.
- Reuse the staged workflow already added to the project: triage, isolate, prove, explain.

## Report Design
Add a report-oriented SQL layer and a small CLI entry point.

SQL responsibilities:
- produce ranked findings with severity, evidence, summary, and next-step guidance
- expose client journey/session outputs that can be embedded directly into a report
- expose Wi-Fi 7 / MLO findings as explicit sections rather than free-form notes

CLI responsibilities:
- load the SQL pack
- run a chosen report workflow against either PCAP or JSONL input
- render markdown with stable headings and compact tables
- optionally write the report to a file for GitHub issues, docs, or case notes

Expected markdown structure:
- Executive Summary
- Top Findings
- Client Journeys
- Wi-Fi 7 / MLO Observations
- Recommended Next Checks

## Wi-Fi 7 / MLO Analytics
Add focused macros for two problem classes.

Link health and imbalance:
- per-link frame count, RSSI summary, and channel width
- link-to-link imbalance detection for weak or underused links
- explicit flags when one link looks materially worse than its peers

State transitions and missing links:
- ordered link activity by MLD or link-specific client MAC
- detection of links that appear in capabilities but never show meaningful progress
- detection of links that disappear after initial visibility
- summary strings that explain whether the problem looks like dropout, partial activation, or normal asymmetric use

## Repository Changes
- Add report CLI module under `src/wifiduck_tools/`
- Add new SQL modules for Wi-Fi 7 link analytics and report assembly
- Add example playbooks and case packs that exercise report generation
- Add deterministic tests for markdown rendering and new Wi-Fi 7 macros

## Constraints
- Do not duplicate detection logic between SQL and Python.
- Do not require external services or non-reproducible data for tests.
- Keep outputs compact enough to read in a terminal and useful enough to paste into issues.
- Treat Wi-Fi 7 observations conservatively when captures do not expose all expected link metadata.

## Success Criteria
- A user can run one command and get a readable markdown incident report from a capture or JSONL fixture.
- The report highlights existing roam and client-experience failures in plain language.
- Wi-Fi 7 / MLO sections can identify link imbalance and missing-link patterns from the bundled fixture path.
- The new macros and CLI are covered by automated tests and documented in the README and example folders.
