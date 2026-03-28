-- Wi-Fi 7 report-oriented workflow
.read sql/wifiduck.sql

SELECT * FROM wd_wifi7_link_health_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
SELECT * FROM wd_wifi7_missing_links_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
SELECT * FROM wd_wifi7_link_transitions_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);
