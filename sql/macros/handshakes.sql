CREATE OR REPLACE MACRO wd_auth_assoc_loops_jsonl(jsonl_file, top_n) AS TABLE
WITH frames AS (
  SELECT
    tx_addr,
    rx_addr,
    subtype,
    ts,
    CASE WHEN subtype = 0 THEN 1 ELSE 0 END AS is_assoc_request,
    CASE WHEN subtype = 11 THEN 1 ELSE 0 END AS is_auth
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE subtype IN (0, 11)
    AND tx_addr IS NOT NULL
), assoc_windows AS (
  SELECT
    tx_addr,
    rx_addr,
    MIN(ts) FILTER (WHERE subtype = 0) AS first_assoc_ts
  FROM frames
  GROUP BY tx_addr, rx_addr
  HAVING MIN(ts) FILTER (WHERE subtype = 0) IS NOT NULL
), pre_assoc AS (
  SELECT
    assoc_windows.tx_addr,
    assoc_windows.rx_addr,
    SUM(CASE WHEN frames.tx_addr = assoc_windows.tx_addr AND frames.subtype = 11 THEN 1 ELSE 0 END) AS auth_frames,
    SUM(CASE WHEN frames.tx_addr = assoc_windows.tx_addr AND frames.subtype = 0 THEN 1 ELSE 0 END) AS assoc_request_frames
  FROM assoc_windows
  JOIN frames
    ON assoc_windows.tx_addr = frames.tx_addr
   AND assoc_windows.rx_addr = frames.rx_addr
   AND frames.ts <= assoc_windows.first_assoc_ts
  GROUP BY assoc_windows.tx_addr, assoc_windows.rx_addr
)
SELECT
  tx_addr,
  rx_addr,
  auth_frames,
  assoc_request_frames,
  auth_frames + assoc_request_frames AS handshake_attempt_frames,
  CASE
    WHEN auth_frames >= 3 THEN 'retry_loop'
    WHEN auth_frames = 2 THEN 'double_auth'
    ELSE 'normal'
  END AS status
FROM pre_assoc
ORDER BY handshake_attempt_frames DESC, tx_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_auth_assoc_loops(pcap_file, top_n) AS TABLE
WITH frames AS (
  SELECT
    tx_addr,
    rx_addr,
    subtype,
    ts,
    CASE WHEN subtype = 0 THEN 1 ELSE 0 END AS is_assoc_request,
    CASE WHEN subtype = 11 THEN 1 ELSE 0 END AS is_auth
  FROM wd_wifi_packets(pcap_file)
  WHERE subtype IN (0, 11)
    AND tx_addr IS NOT NULL
), assoc_windows AS (
  SELECT
    tx_addr,
    rx_addr,
    MIN(ts) FILTER (WHERE subtype = 0) AS first_assoc_ts
  FROM frames
  GROUP BY tx_addr, rx_addr
  HAVING MIN(ts) FILTER (WHERE subtype = 0) IS NOT NULL
), pre_assoc AS (
  SELECT
    assoc_windows.tx_addr,
    assoc_windows.rx_addr,
    SUM(CASE WHEN frames.tx_addr = assoc_windows.tx_addr AND frames.subtype = 11 THEN 1 ELSE 0 END) AS auth_frames,
    SUM(CASE WHEN frames.tx_addr = assoc_windows.tx_addr AND frames.subtype = 0 THEN 1 ELSE 0 END) AS assoc_request_frames
  FROM assoc_windows
  JOIN frames
    ON assoc_windows.tx_addr = frames.tx_addr
   AND assoc_windows.rx_addr = frames.rx_addr
   AND frames.ts <= assoc_windows.first_assoc_ts
  GROUP BY assoc_windows.tx_addr, assoc_windows.rx_addr
)
SELECT
  tx_addr,
  rx_addr,
  auth_frames,
  assoc_request_frames,
  auth_frames + assoc_request_frames AS handshake_attempt_frames,
  CASE
    WHEN auth_frames >= 3 THEN 'retry_loop'
    WHEN auth_frames = 2 THEN 'double_auth'
    ELSE 'normal'
  END AS status
FROM pre_assoc
ORDER BY handshake_attempt_frames DESC, tx_addr ASC
LIMIT top_n;

