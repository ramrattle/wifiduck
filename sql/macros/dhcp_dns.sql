CREATE OR REPLACE MACRO wd_dns_dhcp_gaps_jsonl(jsonl_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
), events AS (
  SELECT
    tx_addr,
    MIN(CASE WHEN dhcp_hostname IS NOT NULL THEN ts END) AS first_dhcp_ts,
    MIN(CASE WHEN dns_query IS NOT NULL THEN ts END) AS first_dns_ts,
    COUNT(CASE WHEN dns_query IS NOT NULL THEN 1 END) AS dns_packets,
    COUNT(CASE WHEN dhcp_hostname IS NOT NULL THEN 1 END) AS dhcp_packets
  FROM base
  WHERE tx_addr IS NOT NULL
  GROUP BY tx_addr
)
SELECT
  tx_addr,
  dhcp_packets,
  dns_packets,
  first_dhcp_ts,
  first_dns_ts,
  CASE
    WHEN first_dhcp_ts IS NOT NULL AND first_dns_ts IS NOT NULL
      THEN CAST(ROUND((first_dns_ts - first_dhcp_ts) * 1000) AS BIGINT)
    ELSE NULL
  END AS dhcp_to_dns_ms
FROM events
ORDER BY dhcp_to_dns_ms DESC NULLS LAST, dns_packets ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_dns_dhcp_gaps(pcap_file, top_n) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
), events AS (
  SELECT
    tx_addr,
    MIN(CASE WHEN dhcp_hostname IS NOT NULL THEN ts END) AS first_dhcp_ts,
    MIN(CASE WHEN dns_query IS NOT NULL THEN ts END) AS first_dns_ts,
    COUNT(CASE WHEN dns_query IS NOT NULL THEN 1 END) AS dns_packets,
    COUNT(CASE WHEN dhcp_hostname IS NOT NULL THEN 1 END) AS dhcp_packets
  FROM base
  WHERE tx_addr IS NOT NULL
  GROUP BY tx_addr
)
SELECT
  tx_addr,
  dhcp_packets,
  dns_packets,
  first_dhcp_ts,
  first_dns_ts,
  CASE
    WHEN first_dhcp_ts IS NOT NULL AND first_dns_ts IS NOT NULL
      THEN CAST(ROUND((first_dns_ts - first_dhcp_ts) * 1000) AS BIGINT)
    ELSE NULL
  END AS dhcp_to_dns_ms
FROM events
ORDER BY dhcp_to_dns_ms DESC NULLS LAST, dns_packets ASC
LIMIT top_n;

