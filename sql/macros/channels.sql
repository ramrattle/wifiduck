CREATE OR REPLACE MACRO wd_channel_health_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE channel_freq_mhz IS NOT NULL
)
SELECT
  channel_freq_mhz,
  COUNT(*) AS frames,
  ROUND(AVG(rssi_dbm), 2) AS avg_rssi_dbm,
  ROUND(100.0 * SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS retry_pct,
  COUNT(DISTINCT tx_addr) AS active_transmitters
FROM base
GROUP BY channel_freq_mhz
ORDER BY frames DESC, retry_pct DESC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_channel_health(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
  WHERE channel_freq_mhz IS NOT NULL
)
SELECT
  channel_freq_mhz,
  COUNT(*) AS frames,
  ROUND(AVG(rssi_dbm), 2) AS avg_rssi_dbm,
  ROUND(100.0 * SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS retry_pct,
  COUNT(DISTINCT tx_addr) AS active_transmitters
FROM base
GROUP BY channel_freq_mhz
ORDER BY frames DESC, retry_pct DESC
LIMIT top_n;

