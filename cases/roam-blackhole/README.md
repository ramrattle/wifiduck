# Roam Blackhole

This case shows a client that reassociates repeatedly and never reaches DHCP or DNS afterward.

Use it when users report "the roam looked fine, but the app stayed dead."

Fixture:
- `sample-data/jsonl/wpa_induction_fixture.jsonl`

Primary signal:
- `wd_post_roam_blackhole_jsonl(...)` returns `status = 'suspected_blackhole'`

Workflow:
1. Run the capture report to rank the finding.
2. Confirm the client is roam-heavy with the packet histogram.
3. Use the session view to show reassociation without higher-layer recovery.
