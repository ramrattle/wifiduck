-- Real-world inspired Wi-Fi 7 diagnostics using the bundled Wi-Fi 7 fixture.
-- Load macros first:
--   .read sql/wifiduck.sql

-- 1) MLO overview
SELECT * FROM wd_mlo_overview_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- 2) Staged triage report
SELECT * FROM wd_capture_report_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- 3) Sessionized proof of the first-attempt auth/assoc anomaly
SELECT *
FROM wd_connection_sessions_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20)
WHERE subject_addr = 'a2:02:a5:e0:54:5f';

-- 4) Wi-Fi 7 capability summary
SELECT * FROM wd_wifi7_capabilities_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- 5) Raw auth/assoc loop detail
SELECT * FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- Summary hint:
-- Problem seen when a Wi-Fi 7/MLO client shows retry_loop before the first association request.
-- This mirrors real public analysis where the client retries authentication before association succeeds.
