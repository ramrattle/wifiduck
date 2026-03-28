CREATE OR REPLACE MACRO wd_connection_sessions_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    ts,
    packet_num,
    subject_addr,
    peer_addr,
    packet_class,
    subtype,
    tx_addr,
    rx_addr,
    dns_query,
    dhcp_hostname
  FROM wd_classified_packets_jsonl(jsonl_file)
  WHERE subject_addr IS NOT NULL
    AND (
      packet_class IN ('authentication', 'association', 'reassociation', 'dns', 'dhcp')
      OR subtype IN (0, 2, 11)
    )
), client_side AS (
  SELECT *
  FROM base
  WHERE tx_addr = subject_addr
     OR packet_class IN ('dns', 'dhcp')
), session_edges AS (
  SELECT
    *,
    CASE
      WHEN LAG(ts) OVER session_window IS NULL THEN 1
      WHEN ts - LAG(ts) OVER session_window > 5.0 THEN 1
      ELSE 0
    END AS is_new_session
  FROM client_side
  WINDOW session_window AS (PARTITION BY subject_addr, peer_addr ORDER BY ts, packet_num)
), numbered AS (
  SELECT
    *,
    SUM(is_new_session) OVER (
      PARTITION BY subject_addr, peer_addr
      ORDER BY ts, packet_num
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS session_id
  FROM session_edges
), summary AS (
  SELECT
    subject_addr,
    peer_addr,
    session_id,
    COUNT(*) AS session_frames,
    SUM(CASE WHEN packet_class = 'authentication' THEN 1 ELSE 0 END) AS auth_frames,
    SUM(CASE WHEN subtype = 0 THEN 1 ELSE 0 END) AS assoc_request_frames,
    SUM(CASE WHEN packet_class = 'reassociation' THEN 1 ELSE 0 END) AS reassociation_frames,
    SUM(CASE WHEN packet_class IN ('dhcp', 'dns') THEN 1 ELSE 0 END) AS l3_frames,
    MIN(ts) AS first_seen,
    MAX(ts) AS last_seen
  FROM numbered
  GROUP BY subject_addr, peer_addr, session_id
)
SELECT
  subject_addr,
  peer_addr,
  session_id,
  CASE
    WHEN reassociation_frames > 0 THEN 'roam_attempt'
    WHEN auth_frames > 0 OR assoc_request_frames > 0 THEN 'join_attempt'
    ELSE 'l3_follow_up'
  END AS session_kind,
  session_frames,
  auth_frames,
  assoc_request_frames,
  reassociation_frames,
  l3_frames,
  CAST(ROUND((last_seen - first_seen) * 1000) AS BIGINT) AS session_window_ms,
  CASE
    WHEN reassociation_frames >= 2 AND l3_frames = 0 THEN 'mobility_failure'
    WHEN auth_frames >= 3 AND assoc_request_frames >= 1 THEN 'retry_loop'
    WHEN reassociation_frames >= 1 AND l3_frames >= 1 THEN 'recovered'
    WHEN assoc_request_frames >= 1 AND l3_frames >= 1 THEN 'completed'
    ELSE 'in_progress'
  END AS status,
  CASE
    WHEN reassociation_frames >= 2 AND l3_frames = 0 THEN 'Client kept reassociating but never reached DHCP or DNS.'
    WHEN auth_frames >= 3 AND assoc_request_frames >= 1 THEN 'Authentication repeated several times before the association request.'
    WHEN reassociation_frames >= 1 AND l3_frames >= 1 THEN 'Client roamed and resumed higher-layer traffic.'
    WHEN assoc_request_frames >= 1 AND l3_frames >= 1 THEN 'Client completed join traffic and reached higher-layer activity.'
    ELSE 'Client activity is incomplete and needs packet-level review.'
  END AS summary
FROM summary
ORDER BY session_frames DESC, subject_addr ASC, peer_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_connection_sessions(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT
    ts,
    packet_num,
    subject_addr,
    peer_addr,
    packet_class,
    subtype,
    tx_addr,
    rx_addr,
    dns_query,
    dhcp_hostname
  FROM wd_classified_packets(pcap_file)
  WHERE subject_addr IS NOT NULL
    AND (
      packet_class IN ('authentication', 'association', 'reassociation', 'dns', 'dhcp')
      OR subtype IN (0, 2, 11)
    )
), client_side AS (
  SELECT *
  FROM base
  WHERE tx_addr = subject_addr
     OR packet_class IN ('dns', 'dhcp')
), session_edges AS (
  SELECT
    *,
    CASE
      WHEN LAG(ts) OVER session_window IS NULL THEN 1
      WHEN ts - LAG(ts) OVER session_window > 5.0 THEN 1
      ELSE 0
    END AS is_new_session
  FROM client_side
  WINDOW session_window AS (PARTITION BY subject_addr, peer_addr ORDER BY ts, packet_num)
), numbered AS (
  SELECT
    *,
    SUM(is_new_session) OVER (
      PARTITION BY subject_addr, peer_addr
      ORDER BY ts, packet_num
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS session_id
  FROM session_edges
), summary AS (
  SELECT
    subject_addr,
    peer_addr,
    session_id,
    COUNT(*) AS session_frames,
    SUM(CASE WHEN packet_class = 'authentication' THEN 1 ELSE 0 END) AS auth_frames,
    SUM(CASE WHEN subtype = 0 THEN 1 ELSE 0 END) AS assoc_request_frames,
    SUM(CASE WHEN packet_class = 'reassociation' THEN 1 ELSE 0 END) AS reassociation_frames,
    SUM(CASE WHEN packet_class IN ('dhcp', 'dns') THEN 1 ELSE 0 END) AS l3_frames,
    MIN(ts) AS first_seen,
    MAX(ts) AS last_seen
  FROM numbered
  GROUP BY subject_addr, peer_addr, session_id
)
SELECT
  subject_addr,
  peer_addr,
  session_id,
  CASE
    WHEN reassociation_frames > 0 THEN 'roam_attempt'
    WHEN auth_frames > 0 OR assoc_request_frames > 0 THEN 'join_attempt'
    ELSE 'l3_follow_up'
  END AS session_kind,
  session_frames,
  auth_frames,
  assoc_request_frames,
  reassociation_frames,
  l3_frames,
  CAST(ROUND((last_seen - first_seen) * 1000) AS BIGINT) AS session_window_ms,
  CASE
    WHEN reassociation_frames >= 2 AND l3_frames = 0 THEN 'mobility_failure'
    WHEN auth_frames >= 3 AND assoc_request_frames >= 1 THEN 'retry_loop'
    WHEN reassociation_frames >= 1 AND l3_frames >= 1 THEN 'recovered'
    WHEN assoc_request_frames >= 1 AND l3_frames >= 1 THEN 'completed'
    ELSE 'in_progress'
  END AS status,
  CASE
    WHEN reassociation_frames >= 2 AND l3_frames = 0 THEN 'Client kept reassociating but never reached DHCP or DNS.'
    WHEN auth_frames >= 3 AND assoc_request_frames >= 1 THEN 'Authentication repeated several times before the association request.'
    WHEN reassociation_frames >= 1 AND l3_frames >= 1 THEN 'Client roamed and resumed higher-layer traffic.'
    WHEN assoc_request_frames >= 1 AND l3_frames >= 1 THEN 'Client completed join traffic and reached higher-layer activity.'
    ELSE 'Client activity is incomplete and needs packet-level review.'
  END AS summary
FROM summary
ORDER BY session_frames DESC, subject_addr ASC, peer_addr ASC
LIMIT top_n;
