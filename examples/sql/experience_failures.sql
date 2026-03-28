-- Vendor-agnostic client experience failure diagnostics.
-- Load macros first:
--   .read sql/core/wifi_packets.sql
--   .read sql/macros/roaming.sql
--   .read sql/macros/dhcp_dns.sql
--   .read sql/macros/client_experience.sql
--   .read sql/macros/handshakes.sql

-- 1) Roam churn: clients that reassociate repeatedly inside a short window
SELECT * FROM wd_roam_health_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);

-- Summary hint:
-- Problem seen when roam_event_count is high and status = 'unstable'.

-- 2) Post-roam blackhole: roam succeeded but no DHCP/DNS activity follows
SELECT * FROM wd_post_roam_blackhole_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);

-- Summary hint:
-- Problem seen when status = 'suspected_blackhole' and first_dhcp_or_dns_ts is null.

-- 3) Excessive pre-association loop
SELECT * FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);

-- Summary hint:
-- Problem seen when status = 'retry_loop' and auth_frames is unusually high before association.
