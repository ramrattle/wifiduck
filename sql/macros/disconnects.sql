CREATE OR REPLACE MACRO wd_disconnect_reasons_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
  WHERE reason_code IS NOT NULL
)
SELECT
  reason_code,
  COUNT(*) AS frame_count,
  COUNT(DISTINCT tx_addr) AS unique_transmitters,
  COUNT(DISTINCT rx_addr) AS unique_receivers
FROM base
GROUP BY reason_code
ORDER BY frame_count DESC, reason_code ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_disconnect_reasons(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
  WHERE reason_code IS NOT NULL
)
SELECT
  reason_code,
  COUNT(*) AS frame_count,
  COUNT(DISTINCT tx_addr) AS unique_transmitters,
  COUNT(DISTINCT rx_addr) AS unique_receivers
FROM base
GROUP BY reason_code
ORDER BY frame_count DESC, reason_code ASC
LIMIT top_n;

