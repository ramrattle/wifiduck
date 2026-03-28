-- JSONL-backed examples for environments without the wireduck extension.
SELECT * FROM wd_retry_hotspots_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10);
SELECT * FROM wd_dns_dhcp_gaps_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10);
SELECT * FROM wd_mlo_overview_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);

