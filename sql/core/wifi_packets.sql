CREATE OR REPLACE MACRO wd_wifi_packets_jsonl(jsonl_file) AS TABLE
SELECT
  CAST(ts AS DOUBLE) AS ts,
  CAST(packet_num AS BIGINT) AS packet_num,
  CAST(tx_addr AS VARCHAR) AS tx_addr,
  CAST(rx_addr AS VARCHAR) AS rx_addr,
  CAST(subtype AS INTEGER) AS subtype,
  CAST(retry_flag AS INTEGER) AS retry_flag,
  CAST(reason_code AS INTEGER) AS reason_code,
  CAST(channel_freq_mhz AS INTEGER) AS channel_freq_mhz,
  CAST(rssi_dbm AS DOUBLE) AS rssi_dbm,
  CAST(dns_query AS VARCHAR) AS dns_query,
  CAST(dhcp_hostname AS VARCHAR) AS dhcp_hostname,
  CAST(mld_mac_addr AS VARCHAR) AS mld_mac_addr,
  CAST(link_id AS INTEGER) AS link_id,
  CAST(eht_sta_profile_count AS INTEGER) AS eht_sta_profile_count,
  CAST(mld_id_present AS INTEGER) AS mld_id_present,
  CAST(channel_width_mhz AS INTEGER) AS channel_width_mhz,
  CAST(is_6ghz AS INTEGER) AS is_6ghz
FROM read_json_auto(jsonl_file, format = 'newline_delimited');

CREATE OR REPLACE MACRO wd_wifi_packets(pcap_file) AS TABLE
FROM query(format($$
SELECT
  ts,
  packet_num,
  COALESCE(protocols['wlan']['wlan.ta'], protocols['wlan']['wlan.sa'])::VARCHAR AS tx_addr,
  COALESCE(protocols['wlan']['wlan.ra'], protocols['wlan']['wlan.da'])::VARCHAR AS rx_addr,
  TRY_CAST(regexp_extract(protocols['wlan']['wlan.fc.type_subtype']::VARCHAR, '0x([0-9a-fA-F]+)', 1) AS INTEGER) AS subtype,
  TRY_CAST(protocols['wlan']['wlan.fc.retry'] AS INTEGER) AS retry_flag,
  TRY_CAST(protocols['wlan']['wlan.fixed.reason_code'] AS INTEGER) AS reason_code,
  TRY_CAST(protocols['radiotap']['radiotap.channel.freq'] AS INTEGER) AS channel_freq_mhz,
  TRY_CAST(protocols['radiotap']['radiotap.dbm_antsignal'] AS DOUBLE) AS rssi_dbm,
  protocols['dns']['dns.qry.name']::VARCHAR AS dns_query,
  protocols['dhcp']['dhcp.option.hostname']::VARCHAR AS dhcp_hostname,
  protocols['wlan']['wlan.eht.common_info.mld_mac_addr']::VARCHAR AS mld_mac_addr,
  TRY_CAST(protocols['wlan']['wlan.eht.multi_link.link_id'] AS INTEGER) AS link_id,
  COALESCE(
    TRY_CAST(protocols['wlan']['wlan.eht.multi_link.type_0.sta_profile_count'] AS INTEGER),
    TRY_CAST(protocols['wlan']['wlan.eht.multi_link.type_1.sta_profile_count'] AS INTEGER),
    TRY_CAST(protocols['wlan']['wlan.eht.multi_link.type_2.sta_profile_count'] AS INTEGER)
  ) AS eht_sta_profile_count,
  TRY_CAST(protocols['wlan']['wlan.eht.multi_link_control.control.basic.mld_id_present'] AS INTEGER) AS mld_id_present,
  TRY_CAST(protocols['wlan']['wlan.ext_tag.bw_indication'] AS INTEGER) AS channel_width_mhz,
  CASE
    WHEN TRY_CAST(protocols['radiotap']['radiotap.channel.freq'] AS INTEGER) >= 5955 THEN 1
    ELSE 0
  END AS is_6ghz
FROM read_pcap(
  '{}',
  ['radiotap','wlan_radio','wlan','llc','eapol','ip','icmp','udp','tcp','dhcp','dns']
)
$$, pcap_file));

