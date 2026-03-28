CREATE OR REPLACE MACRO wd_retry_hotspots_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE tx_addr IS NOT NULL
)
SELECT
  tx_addr,
  COUNT(*) AS total_frames,
  SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) AS retry_frames,
  ROUND(100.0 * SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS retry_pct,
  ROUND(AVG(rssi_dbm), 2) AS avg_rssi_dbm
FROM base
GROUP BY tx_addr
ORDER BY retry_pct DESC, total_frames DESC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_retry_hotspots(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
  WHERE tx_addr IS NOT NULL
)
SELECT
  tx_addr,
  COUNT(*) AS total_frames,
  SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) AS retry_frames,
  ROUND(100.0 * SUM(CASE WHEN retry_flag = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS retry_pct,
  ROUND(AVG(rssi_dbm), 2) AS avg_rssi_dbm
FROM base
GROUP BY tx_addr
ORDER BY retry_pct DESC, total_frames DESC
LIMIT top_n;

