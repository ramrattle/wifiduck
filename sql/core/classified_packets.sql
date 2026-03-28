CREATE OR REPLACE MACRO wd_classified_packets_jsonl(jsonl_file) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets_jsonl(jsonl_file)
)
SELECT
  base.*,
  CASE
    WHEN dns_query IS NOT NULL THEN 'dns'
    WHEN dhcp_hostname IS NOT NULL THEN 'dhcp'
    WHEN subtype = 11 THEN 'authentication'
    WHEN subtype IN (0, 1) THEN 'association'
    WHEN subtype IN (2, 3) THEN 'reassociation'
    WHEN subtype IN (10, 12) THEN 'disconnect'
    WHEN subtype = 13 THEN 'action'
    WHEN subtype = 8 THEN 'beacon'
    WHEN subtype IS NOT NULL THEN 'management'
    ELSE 'data'
  END AS packet_class,
  COALESCE(tx_addr, rx_addr) AS subject_addr,
  rx_addr AS peer_addr,
  CASE WHEN subtype IN (2, 3) THEN 1 ELSE 0 END AS is_roam_signal,
  CASE WHEN subtype = 11 THEN 1 ELSE 0 END AS is_authentication,
  CASE WHEN subtype = 0 THEN 1 ELSE 0 END AS is_assoc_request,
  CASE WHEN subtype = 1 THEN 1 ELSE 0 END AS is_assoc_response,
  CASE WHEN dns_query IS NOT NULL OR dhcp_hostname IS NOT NULL THEN 1 ELSE 0 END AS is_l3_signal
FROM base;

CREATE OR REPLACE MACRO wd_classified_packets(pcap_file) AS TABLE
WITH base AS (
  SELECT * FROM wd_wifi_packets(pcap_file)
)
SELECT
  base.*,
  CASE
    WHEN dns_query IS NOT NULL THEN 'dns'
    WHEN dhcp_hostname IS NOT NULL THEN 'dhcp'
    WHEN subtype = 11 THEN 'authentication'
    WHEN subtype IN (0, 1) THEN 'association'
    WHEN subtype IN (2, 3) THEN 'reassociation'
    WHEN subtype IN (10, 12) THEN 'disconnect'
    WHEN subtype = 13 THEN 'action'
    WHEN subtype = 8 THEN 'beacon'
    WHEN subtype IS NOT NULL THEN 'management'
    ELSE 'data'
  END AS packet_class,
  COALESCE(tx_addr, rx_addr) AS subject_addr,
  rx_addr AS peer_addr,
  CASE WHEN subtype IN (2, 3) THEN 1 ELSE 0 END AS is_roam_signal,
  CASE WHEN subtype = 11 THEN 1 ELSE 0 END AS is_authentication,
  CASE WHEN subtype = 0 THEN 1 ELSE 0 END AS is_assoc_request,
  CASE WHEN subtype = 1 THEN 1 ELSE 0 END AS is_assoc_response,
  CASE WHEN dns_query IS NOT NULL OR dhcp_hostname IS NOT NULL THEN 1 ELSE 0 END AS is_l3_signal
FROM base;
