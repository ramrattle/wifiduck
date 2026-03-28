-- Wi-Fi 7 MLO auth loop case pack
.read sql/wifiduck.sql

SELECT * FROM wd_mlo_overview_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);

SELECT * FROM wd_capture_report_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);

SELECT *
FROM wd_connection_sessions_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10)
WHERE subject_addr = 'a2:02:a5:e0:54:5f';

SELECT *
FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10)
WHERE tx_addr = 'a2:02:a5:e0:54:5f';
