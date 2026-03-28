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

