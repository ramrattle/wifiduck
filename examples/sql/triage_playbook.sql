-- Triage a single Wi-Fi capture.
SELECT * FROM wd_retry_hotspots('sample-data/pcap/wpa-induction.pcap', 25);
SELECT * FROM wd_disconnect_reasons('sample-data/pcap/wpa-induction.pcap', 25);
SELECT * FROM wd_channel_health('sample-data/pcap/wpa-induction.pcap', 40);
SELECT * FROM wd_roaming_events('sample-data/pcap/wpa-induction-management-only.pcap', 100);
SELECT * FROM wd_dns_dhcp_gaps('sample-data/pcap/wpa-induction.pcap', 100);
