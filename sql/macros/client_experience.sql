CREATE OR REPLACE MACRO wd_post_roam_blackhole_jsonl(jsonl_file, top_n) AS TABLE
WITH roam_events AS (
  SELECT
    tx_addr,
    MAX(ts) AS roam_ts
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE subtype IN (2, 3, 11, 12)
    AND tx_addr IS NOT NULL
  GROUP BY tx_addr
), l3_events AS (
  SELECT
    tx_addr,
    MIN(ts) AS first_dhcp_or_dns_ts
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE tx_addr IS NOT NULL
    AND (dhcp_hostname IS NOT NULL OR dns_query IS NOT NULL)
  GROUP BY tx_addr
)
SELECT
  roam_events.tx_addr,
  roam_events.roam_ts,
  l3_events.first_dhcp_or_dns_ts,
  CASE
    WHEN l3_events.first_dhcp_or_dns_ts IS NOT NULL
      THEN CAST(ROUND((l3_events.first_dhcp_or_dns_ts - roam_events.roam_ts) * 1000) AS BIGINT)
    ELSE NULL
  END AS l3_gap_ms,
  CASE
    WHEN l3_events.first_dhcp_or_dns_ts IS NULL THEN 'suspected_blackhole'
    WHEN l3_events.first_dhcp_or_dns_ts - roam_events.roam_ts > 1.0 THEN 'slow_recovery'
    ELSE 'recovered'
  END AS status
FROM roam_events
LEFT JOIN l3_events
  ON roam_events.tx_addr = l3_events.tx_addr
ORDER BY roam_events.roam_ts DESC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_post_roam_blackhole(pcap_file, top_n) AS TABLE
WITH roam_events AS (
  SELECT
    tx_addr,
    MAX(ts) AS roam_ts
  FROM wd_wifi_packets(pcap_file)
  WHERE subtype IN (2, 3, 11, 12)
    AND tx_addr IS NOT NULL
  GROUP BY tx_addr
), l3_events AS (
  SELECT
    tx_addr,
    MIN(ts) AS first_dhcp_or_dns_ts
  FROM wd_wifi_packets(pcap_file)
  WHERE tx_addr IS NOT NULL
    AND (dhcp_hostname IS NOT NULL OR dns_query IS NOT NULL)
  GROUP BY tx_addr
)
SELECT
  roam_events.tx_addr,
  roam_events.roam_ts,
  l3_events.first_dhcp_or_dns_ts,
  CASE
    WHEN l3_events.first_dhcp_or_dns_ts IS NOT NULL
      THEN CAST(ROUND((l3_events.first_dhcp_or_dns_ts - roam_events.roam_ts) * 1000) AS BIGINT)
    ELSE NULL
  END AS l3_gap_ms,
  CASE
    WHEN l3_events.first_dhcp_or_dns_ts IS NULL THEN 'suspected_blackhole'
    WHEN l3_events.first_dhcp_or_dns_ts - roam_events.roam_ts > 1.0 THEN 'slow_recovery'
    ELSE 'recovered'
  END AS status
FROM roam_events
LEFT JOIN l3_events
  ON roam_events.tx_addr = l3_events.tx_addr
ORDER BY roam_events.roam_ts DESC
LIMIT top_n;

