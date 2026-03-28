# Wi-Fi 7 MLO Link Imbalance

This case shows an MLD that advertises two links, but only one link carries meaningful join progress while the other looks weaker and incomplete.

Use it when a Wi-Fi 7 capture shows MLO visibility, but the client experience still depends on a single healthy link.

Fixture:
- `sample-data/jsonl/wifi7_mlo_fixture.jsonl`

Primary signals:
- `wd_wifi7_link_health_jsonl(...)` returns `imbalance_status = 'imbalanced'`
- `wd_wifi7_missing_links_jsonl(...)` returns `status = 'partial_activation'`

Workflow:
1. Run the markdown report or capture report to rank the issue.
2. Confirm per-link RSSI and width imbalance.
3. Prove that only one link shows join-progress visibility.
