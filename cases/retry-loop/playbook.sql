-- Retry loop case pack
.read sql/wifiduck.sql

SELECT * FROM wd_capture_report_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10);

SELECT *
FROM wd_connection_sessions_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10)
WHERE subject_addr = 'ee:ee:ee:ee:ee:ee';

SELECT *
FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 10)
WHERE tx_addr = 'ee:ee:ee:ee:ee:ee';
