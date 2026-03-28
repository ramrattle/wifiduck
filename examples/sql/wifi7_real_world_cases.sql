-- Real-world inspired Wi-Fi 7 diagnostics using the bundled Wi-Fi 7 fixture.
-- Load macros first:
--   .read sql/core/wifi_packets.sql
--   .read sql/macros/wifi7.sql
--   .read sql/macros/handshakes.sql

-- 1) MLO overview
SELECT * FROM wd_mlo_overview_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- 2) Wi-Fi 7 capability summary
SELECT * FROM wd_wifi7_capabilities_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- 3) First-attempt auth/assoc anomaly
SELECT * FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 20);

-- Summary hint:
-- Problem seen when a Wi-Fi 7/MLO client shows retry_loop before the first association request.
-- This mirrors real public analysis where the client retries authentication before association succeeds.
