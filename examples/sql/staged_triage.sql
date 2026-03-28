-- Staged Wi-Fi triage workflow.
-- Load macros first:
--   .read sql/wifiduck.sql

-- Stage 1: triage
-- Rank the strongest findings in the capture before drilling into any one client.
SELECT * FROM wd_capture_report_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);

-- Stage 2: isolate
-- Understand whether the suspect is dominated by roam churn, authentication, or higher-layer follow-up.
SELECT * FROM wd_packet_class_histogram_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);

-- Stage 3: prove
-- Sessionize the client timeline to prove whether the failure is a join loop or a post-roam blackhole.
SELECT *
FROM wd_connection_sessions_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20)
WHERE subject_addr IN ('cc:cc:cc:cc:cc:cc', 'ee:ee:ee:ee:ee:ee');

-- Stage 4: explain
-- Pull the specific diagnostic macro that names the failure mode and next step.
SELECT * FROM wd_post_roam_blackhole_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);
SELECT * FROM wd_auth_assoc_loops_jsonl('sample-data/jsonl/wpa_induction_fixture.jsonl', 20);
