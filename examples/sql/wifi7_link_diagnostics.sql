-- Focused Wi-Fi 7 link diagnostics using the bundled MLO fixture.
-- Load macros first:
--   .read sql/core/wifi_packets.sql
--   .read sql/macros/wifi7.sql

-- A) Link inventory with basic radio metadata
SELECT
  mld_mac_addr,
  link_id,
  COUNT(*) AS frame_count,
  AVG(rssi_dbm) AS avg_rssi_dbm,
  MIN(channel_freq_mhz) AS channel_freq_mhz,
  MAX(channel_width_mhz) AS channel_width_mhz
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
GROUP BY mld_mac_addr, link_id
ORDER BY mld_mac_addr, link_id;

-- B) Flag links that look materially weaker than the best link in the same MLD
WITH link_stats AS (
  SELECT
    mld_mac_addr,
    link_id,
    AVG(rssi_dbm) AS avg_rssi_dbm
  FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
  WHERE mld_mac_addr IS NOT NULL
  GROUP BY mld_mac_addr, link_id
), ranked AS (
  SELECT
    mld_mac_addr,
    link_id,
    avg_rssi_dbm,
    MAX(avg_rssi_dbm) OVER (PARTITION BY mld_mac_addr) AS best_link_rssi_dbm
  FROM link_stats
)
SELECT
  mld_mac_addr,
  link_id,
  avg_rssi_dbm,
  best_link_rssi_dbm,
  ROUND(best_link_rssi_dbm - avg_rssi_dbm, 2) AS deficit_db,
  CASE
    WHEN best_link_rssi_dbm - avg_rssi_dbm >= 6 THEN 'investigate'
    ELSE 'balanced'
  END AS status
FROM ranked
ORDER BY mld_mac_addr, link_id;

-- C) Check whether all observed links stay in 6 GHz
SELECT
  mld_mac_addr,
  SUM(CASE WHEN is_6ghz = 1 THEN 1 ELSE 0 END) AS six_ghz_frames,
  COUNT(*) AS total_frames,
  CASE
    WHEN SUM(CASE WHEN is_6ghz = 1 THEN 1 ELSE 0 END) = COUNT(*) THEN 'all_6ghz'
    ELSE 'mixed_band'
  END AS band_status
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
GROUP BY mld_mac_addr;

-- D) Inspect observed link switch order
SELECT
  packet_num,
  ts,
  mld_mac_addr,
  link_id,
  channel_freq_mhz
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
ORDER BY packet_num;
