# Wi-Fi 7 MLO Auth Loop

This case mirrors an MLO-era Wi-Fi 7 first-attempt failure where authentication repeats before association.

Use it when a Wi-Fi 7 capture shows MLD metadata but the client still struggles to complete the first secure join.

Fixture:
- `sample-data/jsonl/wifi7_mlo_fixture.jsonl`

Primary signal:
- `wd_capture_report_jsonl(...)` reports `auth_assoc_loop` for the link-specific client MAC

Workflow:
1. Confirm MLO visibility with `wd_mlo_overview_jsonl(...)`.
2. Rank findings with the capture report.
3. Prove the first-attempt failure with the session view and handshake macro.
