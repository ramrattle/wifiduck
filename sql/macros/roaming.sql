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

