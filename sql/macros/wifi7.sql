CREATE OR REPLACE MACRO wd_mlo_overview_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE mld_mac_addr IS NOT NULL
)
SELECT
  mld_mac_addr,
  COUNT(*) AS frame_count,
  COUNT(DISTINCT link_id) AS distinct_link_ids,
  MAX(eht_sta_profile_count) AS sta_profile_count,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM base
GROUP BY mld_mac_addr
ORDER BY frame_count DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_mlo_overview(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
  WHERE mld_mac_addr IS NOT NULL
)
SELECT
  mld_mac_addr,
  COUNT(*) AS frame_count,
  COUNT(DISTINCT link_id) AS distinct_link_ids,
  MAX(eht_sta_profile_count) AS sta_profile_count,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM base
GROUP BY mld_mac_addr
ORDER BY frame_count DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_capabilities_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
)
SELECT
  SUM(CASE WHEN is_6ghz = 1 THEN 1 ELSE 0 END) AS six_ghz_frames,
  SUM(CASE WHEN channel_width_mhz >= 160 THEN 1 ELSE 0 END) AS wide_channel_frames,
  SUM(CASE WHEN mld_id_present = 1 THEN 1 ELSE 0 END) AS mld_id_present_frames,
  COUNT(DISTINCT mld_mac_addr) FILTER (WHERE mld_mac_addr IS NOT NULL) AS observed_mld_count
FROM base;

CREATE OR REPLACE MACRO wd_wifi7_capabilities(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
)
SELECT
  SUM(CASE WHEN is_6ghz = 1 THEN 1 ELSE 0 END) AS six_ghz_frames,
  SUM(CASE WHEN channel_width_mhz >= 160 THEN 1 ELSE 0 END) AS wide_channel_frames,
  SUM(CASE WHEN mld_id_present = 1 THEN 1 ELSE 0 END) AS mld_id_present_frames,
  COUNT(DISTINCT mld_mac_addr) FILTER (WHERE mld_mac_addr IS NOT NULL) AS observed_mld_count
FROM base;

CREATE OR REPLACE MACRO wd_wifi7_link_health_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    link_id,
    COUNT(*) AS frames,
    AVG(rssi_dbm) AS avg_rssi_dbm,
    MAX(channel_width_mhz) AS channel_width_mhz
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE mld_mac_addr IS NOT NULL
    AND link_id IS NOT NULL
  GROUP BY mld_mac_addr, link_id
), ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY mld_mac_addr
      ORDER BY avg_rssi_dbm DESC, frames DESC, link_id ASC
    ) AS best_rank,
    ROW_NUMBER() OVER (
      PARTITION BY mld_mac_addr
      ORDER BY avg_rssi_dbm ASC, frames ASC, link_id ASC
    ) AS weak_rank
  FROM base
)
SELECT
  strong.mld_mac_addr,
  weak.link_id AS weakest_link_id,
  strong.link_id AS strongest_link_id,
  ROUND(strong.avg_rssi_dbm - weak.avg_rssi_dbm, 2) AS rssi_gap_db,
  strong.frames AS strongest_link_frames,
  weak.frames AS weakest_link_frames,
  strong.channel_width_mhz AS strongest_link_width_mhz,
  weak.channel_width_mhz AS weakest_link_width_mhz,
  CASE
    WHEN strong.avg_rssi_dbm - weak.avg_rssi_dbm >= 10 THEN 'imbalanced'
    ELSE 'balanced'
  END AS imbalance_status
FROM ranked strong
JOIN ranked weak
  ON strong.mld_mac_addr = weak.mld_mac_addr
WHERE strong.best_rank = 1
  AND weak.weak_rank = 1
ORDER BY rssi_gap_db DESC, strong.mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_link_health(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    link_id,
    COUNT(*) AS frames,
    AVG(rssi_dbm) AS avg_rssi_dbm,
    MAX(channel_width_mhz) AS channel_width_mhz
  FROM wd_wifi_packets(pcap_file)
  WHERE mld_mac_addr IS NOT NULL
    AND link_id IS NOT NULL
  GROUP BY mld_mac_addr, link_id
), ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY mld_mac_addr
      ORDER BY avg_rssi_dbm DESC, frames DESC, link_id ASC
    ) AS best_rank,
    ROW_NUMBER() OVER (
      PARTITION BY mld_mac_addr
      ORDER BY avg_rssi_dbm ASC, frames ASC, link_id ASC
    ) AS weak_rank
  FROM base
)
SELECT
  strong.mld_mac_addr,
  weak.link_id AS weakest_link_id,
  strong.link_id AS strongest_link_id,
  ROUND(strong.avg_rssi_dbm - weak.avg_rssi_dbm, 2) AS rssi_gap_db,
  strong.frames AS strongest_link_frames,
  weak.frames AS weakest_link_frames,
  strong.channel_width_mhz AS strongest_link_width_mhz,
  weak.channel_width_mhz AS weakest_link_width_mhz,
  CASE
    WHEN strong.avg_rssi_dbm - weak.avg_rssi_dbm >= 10 THEN 'imbalanced'
    ELSE 'balanced'
  END AS imbalance_status
FROM ranked strong
JOIN ranked weak
  ON strong.mld_mac_addr = weak.mld_mac_addr
WHERE strong.best_rank = 1
  AND weak.weak_rank = 1
ORDER BY rssi_gap_db DESC, strong.mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_link_transitions_jsonl(jsonl_file, top_n) AS TABLE
SELECT
  mld_mac_addr,
  tx_addr AS subject_addr,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen,
  COUNT(DISTINCT link_id) AS observed_links,
  string_agg(CAST(link_id AS VARCHAR), '->' ORDER BY ts, packet_num) AS link_timeline
FROM wd_wifi_packets_jsonl(jsonl_file)
WHERE mld_mac_addr IS NOT NULL
  AND link_id IS NOT NULL
GROUP BY mld_mac_addr, tx_addr
ORDER BY last_seen DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_link_transitions(pcap_file, top_n) AS TABLE
SELECT
  mld_mac_addr,
  tx_addr AS subject_addr,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen,
  COUNT(DISTINCT link_id) AS observed_links,
  string_agg(CAST(link_id AS VARCHAR), '->' ORDER BY ts, packet_num) AS link_timeline
FROM wd_wifi_packets(pcap_file)
WHERE mld_mac_addr IS NOT NULL
  AND link_id IS NOT NULL
GROUP BY mld_mac_addr, tx_addr
ORDER BY last_seen DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_missing_links_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    MAX(COALESCE(eht_sta_profile_count, 0)) AS expected_links,
    COUNT(DISTINCT link_id) FILTER (
      WHERE subtype IN (0, 1, 11)
         OR dns_query IS NOT NULL
         OR dhcp_hostname IS NOT NULL
    ) AS active_links
  FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE mld_mac_addr IS NOT NULL
  GROUP BY mld_mac_addr
)
SELECT
  mld_mac_addr,
  expected_links,
  active_links,
  CASE
    WHEN expected_links > active_links THEN 'partial_activation'
    ELSE 'fully_visible'
  END AS status
FROM base
ORDER BY expected_links DESC, mld_mac_addr ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_wifi7_missing_links(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT
    mld_mac_addr,
    MAX(COALESCE(eht_sta_profile_count, 0)) AS expected_links,
    COUNT(DISTINCT link_id) FILTER (
      WHERE subtype IN (0, 1, 11)
         OR dns_query IS NOT NULL
         OR dhcp_hostname IS NOT NULL
    ) AS active_links
  FROM wd_wifi_packets(pcap_file)
  WHERE mld_mac_addr IS NOT NULL
  GROUP BY mld_mac_addr
)
SELECT
  mld_mac_addr,
  expected_links,
  active_links,
  CASE
    WHEN expected_links > active_links THEN 'partial_activation'
    ELSE 'fully_visible'
  END AS status
FROM base
ORDER BY expected_links DESC, mld_mac_addr ASC
LIMIT top_n;
