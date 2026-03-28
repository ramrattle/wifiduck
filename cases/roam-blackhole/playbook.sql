-- Roam blackhole case pack
.read sql/wifiduck.sql

SELECT * FROM wd_capture_report_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10);

SELECT *
FROM wd_connection_sessions_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10)
WHERE subject_addr = 'cc:cc:cc:cc:cc:cc';

SELECT *
FROM wd_post_roam_blackhole_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10)
WHERE tx_addr = 'cc:cc:cc:cc:cc:cc';
