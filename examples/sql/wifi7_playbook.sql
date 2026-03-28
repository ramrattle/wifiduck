-- Wi-Fi 7 / MLO inspection against JSONL fixtures or user-prepared exports.
-- Load macros first:
--   .read sql/core/wifi_packets.sql
--   .read sql/macros/wifi7.sql

-- 1) Top-level MLD overview
SELECT * FROM wd_mlo_overview_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);

-- 2) 6 GHz / wide-channel / MLD summary
SELECT * FROM wd_wifi7_capabilities_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl', 10);

-- 3) Per-link inventory for each observed MLD
SELECT
  mld_mac_addr,
  link_id,
  channel_freq_mhz,
  channel_width_mhz,
  rssi_dbm
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
ORDER BY mld_mac_addr, link_id;

-- 4) Link-to-link signal imbalance within the same MLD
WITH links AS (
  SELECT
    mld_mac_addr,
    link_id,
    AVG(rssi_dbm) AS avg_rssi_dbm
  FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
  WHERE mld_mac_addr IS NOT NULL
  GROUP BY mld_mac_addr, link_id
)
SELECT
  mld_mac_addr,
  MIN(avg_rssi_dbm) AS weakest_link_rssi_dbm,
  MAX(avg_rssi_dbm) AS strongest_link_rssi_dbm,
  ROUND(MAX(avg_rssi_dbm) - MIN(avg_rssi_dbm), 2) AS rssi_gap_db
FROM links
GROUP BY mld_mac_addr;

-- 5) Distinct channels participating in an MLO exchange
SELECT
  mld_mac_addr,
  COUNT(DISTINCT channel_freq_mhz) AS distinct_channels,
  MIN(channel_freq_mhz) AS lowest_freq_mhz,
  MAX(channel_freq_mhz) AS highest_freq_mhz
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
GROUP BY mld_mac_addr;

-- 6) Timeline view to inspect link sequencing
SELECT
  ts,
  mld_mac_addr,
  link_id,
  tx_addr,
  channel_freq_mhz,
  rssi_dbm
FROM wd_wifi_packets_jsonl('sample-data/jsonl/wifi7_mlo_fixture.jsonl')
WHERE mld_mac_addr IS NOT NULL
ORDER BY ts, link_id;

-- For real Wi-Fi 7 captures with wireduck enabled, use the PCAP-backed macros:
-- SELECT * FROM wd_mlo_overview('sample-data/pcap/your_wifi7_capture.pcapng', 10);
-- SELECT * FROM wd_wifi7_capabilities('sample-data/pcap/your_wifi7_capture.pcapng', 10);
