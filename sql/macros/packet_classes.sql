CREATE OR REPLACE MACRO wd_packet_class_histogram_jsonl(jsonl_file, top_n) AS TABLE
SELECT
  packet_class,
  COUNT(*) AS frames,
  COUNT(DISTINCT subject_addr) AS unique_talkers,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM wd_classified_packets_jsonl(jsonl_file)
WHERE subject_addr IS NOT NULL
GROUP BY packet_class
ORDER BY frames DESC, packet_class ASC
LIMIT top_n;

CREATE OR REPLACE MACRO wd_packet_class_histogram(pcap_file, top_n) AS TABLE
SELECT
  packet_class,
  COUNT(*) AS frames,
  COUNT(DISTINCT subject_addr) AS unique_talkers,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM wd_classified_packets(pcap_file)
WHERE subject_addr IS NOT NULL
GROUP BY packet_class
ORDER BY frames DESC, packet_class ASC
LIMIT top_n;
