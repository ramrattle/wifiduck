# Sample Data Sources

## Bundled public captures
- `sample-data/pcap/wpa-induction.pcap`
  - Source: Wireshark Wiki SampleCaptures
  - Upstream URL: `https://wiki.wireshark.org/uploads/__moin_import__/attachments/SampleCaptures/wpa-Induction.pcap`
  - Notes: 802.11 WPA traffic sample used for retry, disconnect, and management-frame examples.
- `sample-data/pcap/wpa-induction-first-64.pcap`
  - Source: derived from `wpa-induction.pcap`
  - Notes: first 64 packets only; useful for quick smoke checks and short walkthroughs.
- `sample-data/pcap/wpa-induction-management-only.pcap`
  - Source: derived from `wpa-induction.pcap`
  - Notes: management-frame-only subset suitable for roaming and disconnect-focused examples.
- `sample-data/pcap/wpa-eap-tls.pcap.gz`
  - Source: Wireshark Wiki SampleCaptures
  - Upstream URL: `https://wiki.wireshark.org/uploads/__moin_import__/attachments/SampleCaptures/wpa-eap-tls.pcap.gz`
  - Notes: WPA-EAP / rekey traffic sample suitable for authentication and EAP-oriented follow-up work.

## Wi-Fi 7 / MLO reference
- Public lead: Wireshark issue `#19425` references `ieee80211_eht_ml_sta_profile.pcapng`.
  - Issue URL: `https://gitlab.com/wireshark/wireshark/-/issues/19425`
  - Current status: useful for field planning and example design, but the attachment is not directly downloadable in this environment without authentication. Do not bundle it until redistribution and access terms are confirmed.
