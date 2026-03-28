CREATE OR REPLACE MACRO wd_capture_report_jsonl(jsonl_file, top_n) AS TABLE
WITH findings AS (
  SELECT
    'post_roam_blackhole' AS issue_type,
    tx_addr AS subject_addr,
    NULL::VARCHAR AS peer_addr,
    'critical' AS severity,
    status,
    summary,
    next_step,
    roam_ts AS observed_at,
    COALESCE(l3_gap_ms, 999999) AS evidence_score
  FROM wd_post_roam_blackhole_jsonl(jsonl_file, top_n)
  WHERE status IN ('suspected_blackhole', 'slow_recovery')

  UNION ALL

  SELECT
    'auth_assoc_loop' AS issue_type,
    tx_addr AS subject_addr,
    rx_addr AS peer_addr,
    CASE
      WHEN status = 'retry_loop' THEN 'high'
      ELSE 'medium'
    END AS severity,
    status,
    summary,
    next_step,
    NULL::DOUBLE AS observed_at,
    handshake_attempt_frames AS evidence_score
  FROM wd_auth_assoc_loops_jsonl(jsonl_file, top_n)
  WHERE status <> 'normal'

  UNION ALL

  SELECT
    'roam_instability' AS issue_type,
    tx_addr AS subject_addr,
    NULL::VARCHAR AS peer_addr,
    CASE
      WHEN status = 'unstable' THEN 'high'
      ELSE 'low'
    END AS severity,
    status,
    summary,
    next_step,
    NULL::DOUBLE AS observed_at,
    roam_event_count AS evidence_score
  FROM wd_roam_health_jsonl(jsonl_file, top_n)
  WHERE status <> 'stable'
)
SELECT
  issue_type,
  subject_addr,
  peer_addr,
  severity,
  status,
  summary,
  next_step,
  observed_at
FROM findings
ORDER BY
  CASE severity
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    ELSE 4
  END,
  evidence_score DESC,
  subject_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_capture_report(pcap_file, top_n) AS TABLE
WITH findings AS (
  SELECT
    'post_roam_blackhole' AS issue_type,
    tx_addr AS subject_addr,
    NULL::VARCHAR AS peer_addr,
    'critical' AS severity,
    status,
    summary,
    next_step,
    roam_ts AS observed_at,
    COALESCE(l3_gap_ms, 999999) AS evidence_score
  FROM wd_post_roam_blackhole(pcap_file, top_n)
  WHERE status IN ('suspected_blackhole', 'slow_recovery')

  UNION ALL

  SELECT
    'auth_assoc_loop' AS issue_type,
    tx_addr AS subject_addr,
    rx_addr AS peer_addr,
    CASE
      WHEN status = 'retry_loop' THEN 'high'
      ELSE 'medium'
    END AS severity,
    status,
    summary,
    next_step,
    NULL::DOUBLE AS observed_at,
    handshake_attempt_frames AS evidence_score
  FROM wd_auth_assoc_loops(pcap_file, top_n)
  WHERE status <> 'normal'

  UNION ALL

  SELECT
    'roam_instability' AS issue_type,
    tx_addr AS subject_addr,
    NULL::VARCHAR AS peer_addr,
    CASE
      WHEN status = 'unstable' THEN 'high'
      ELSE 'low'
    END AS severity,
    status,
    summary,
    next_step,
    NULL::DOUBLE AS observed_at,
    roam_event_count AS evidence_score
  FROM wd_roam_health(pcap_file, top_n)
  WHERE status <> 'stable'
)
SELECT
  issue_type,
  subject_addr,
  peer_addr,
  severity,
  status,
  summary,
  next_step,
  observed_at
FROM findings
ORDER BY
  CASE severity
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    ELSE 4
  END,
  evidence_score DESC,
  subject_addr ASC
LIMIT top_n;
