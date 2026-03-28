-- Load the macro pack in DuckDB:
--   INSTALL wireduck FROM community;
--   LOAD wireduck;
--   .read sql/wifiduck.sql

SELECT * FROM wd_retry_hotspots('sample-data/pcap/wpa-induction.pcap', 20);
SELECT * FROM wd_disconnect_reasons('sample-data/pcap/wpa-induction.pcap', 20);
SELECT * FROM wd_channel_health('sample-data/pcap/wpa-induction.pcap', 20);

