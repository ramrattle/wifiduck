CREATE OR REPLACE MACRO wd_roaming_events_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE subtype IN (0, 1, 2, 3, 11, 12)
    AND tx_addr IS NOT NULL
)
SELECT
  tx_addr,
  subtype,
  COUNT(*) AS events,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM base
GROUP BY tx_addr, subtype
ORDER BY events DESC, tx_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_roam_health_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    tx_addr,
    ts
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE subtype IN (2, 3)
    AND tx_addr IS NOT NULL
), summary AS (
  SELECT
    tx_addr,
    COUNT(*) AS roam_event_count,
    MIN(ts) AS first_roam_ts,
    MAX(ts) AS last_roam_ts
  FROM base
  GROUP BY tx_addr
)
SELECT
  tx_addr,
  roam_event_count,
  CAST(ROUND((last_roam_ts - first_roam_ts) * 1000) AS BIGINT) AS roam_window_ms,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0 THEN 'unstable'
    ELSE 'stable'
  END AS status,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0
      THEN 'Client reassociated repeatedly inside a short time window.'
    ELSE 'Client roam activity stayed within a normal range.'
  END AS summary,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0
      THEN 'Compare RSSI, target BSSID choice, and post-roam DHCP or DNS activity.'
    ELSE 'No immediate roam follow-up is required.'
  END AS next_step
FROM summary
ORDER BY roam_event_count DESC, tx_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_roaming_events(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
  WHERE subtype IN (0, 1, 2, 3, 11, 12)
    AND tx_addr IS NOT NULL
)
SELECT
  tx_addr,
  subtype,
  COUNT(*) AS events,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM base
GROUP BY tx_addr, subtype
ORDER BY events DESC, tx_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_roam_health(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT
    tx_addr,
    ts
  FROM wd_wifi_packets(pcap_file)
  WHERE subtype IN (2, 3)
    AND tx_addr IS NOT NULL
), summary AS (
  SELECT
    tx_addr,
    COUNT(*) AS roam_event_count,
    MIN(ts) AS first_roam_ts,
    MAX(ts) AS last_roam_ts
  FROM base
  GROUP BY tx_addr
)
SELECT
  tx_addr,
  roam_event_count,
  CAST(ROUND((last_roam_ts - first_roam_ts) * 1000) AS BIGINT) AS roam_window_ms,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0 THEN 'unstable'
    ELSE 'stable'
  END AS status,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0
      THEN 'Client reassociated repeatedly inside a short time window.'
    ELSE 'Client roam activity stayed within a normal range.'
  END AS summary,
  CASE
    WHEN roam_event_count >= 2 AND (last_roam_ts - first_roam_ts) <= 2.0
      THEN 'Compare RSSI, target BSSID choice, and post-roam DHCP or DNS activity.'
    ELSE 'No immediate roam follow-up is required.'
  END AS next_step
FROM summary
ORDER BY roam_event_count DESC, tx_addr ASC
LIMIT top_n;
