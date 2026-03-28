from __future__ import annotations

from argparse import ArgumentParser
from pathlib import Path
import json

from scapy.all import DHCP, DNS, DNSQR, Dot11, Dot11Deauth, Dot11Disas, PcapReader, RadioTap


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_pcap_to_jsonl(input_path: Path, output_path: Path) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    parsed = 0

    with PcapReader(str(input_path)) as pcap_reader, output_path.open("w", encoding="utf-8") as out:
        for packet in pcap_reader:
            if not packet.haslayer(Dot11):
                continue

            dot11 = packet[Dot11]
            retry_flag = None
            try:
                retry_flag = 1 if (int(dot11.FCfield) & 0x8) else 0
            except Exception:
                pass

            reason_code = None
            if packet.haslayer(Dot11Deauth):
                reason_code = int(packet[Dot11Deauth].reason)
            elif packet.haslayer(Dot11Disas):
                reason_code = int(packet[Dot11Disas].reason)

            channel_freq_mhz = None
            rssi_dbm = None
            if packet.haslayer(RadioTap):
                radiotap = packet[RadioTap]
                freq = getattr(radiotap, "ChannelFrequency", None)
                sig = getattr(radiotap, "dBm_AntSignal", None)
                channel_freq_mhz = int(freq) if freq is not None else None
                rssi_dbm = float(sig) if sig is not None else None

            dns_query = None
            if packet.haslayer(DNS) and packet.haslayer(DNSQR):
                qname = packet[DNSQR].qname
                dns_query = qname.decode(errors="ignore") if isinstance(qname, (bytes, bytearray)) else str(qname)

            dhcp_hostname = None
            if packet.haslayer(DHCP):
                for option in packet[DHCP].options:
                    if isinstance(option, tuple) and option[0] == "hostname":
                        dhcp_hostname = str(option[1])
                        break

            parsed += 1
            out.write(
                json.dumps(
                    {
                        "ts": float(packet.time),
                        "packet_num": parsed,
                        "tx_addr": str(dot11.addr2) if dot11.addr2 else None,
                        "rx_addr": str(dot11.addr1) if dot11.addr1 else None,
                        "subtype": int(dot11.subtype),
                        "retry_flag": retry_flag,
                        "reason_code": reason_code,
                        "channel_freq_mhz": channel_freq_mhz,
                        "rssi_dbm": rssi_dbm,
                        "dns_query": dns_query,
                        "dhcp_hostname": dhcp_hostname,
                        "mld_mac_addr": None,
                        "link_id": None,
                        "eht_sta_profile_count": None,
                        "mld_id_present": None,
                        "channel_width_mhz": None,
                        "is_6ghz": 1 if channel_freq_mhz and channel_freq_mhz >= 5955 else 0,
                    }
                )
                + "\n"
            )

    return parsed


def build_parser() -> ArgumentParser:
    parser = ArgumentParser(description="Convert a Wi-Fi packet capture into a JSONL fixture for wifiduck macros.")
    parser.add_argument("--input", type=Path, required=True, help="Path to a .pcap or .pcapng file")
    parser.add_argument("--output", type=Path, required=True, help="Destination JSONL file")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    input_path = args.input.expanduser().resolve()
    output_path = args.output.expanduser().resolve()

    if not input_path.exists():
        raise SystemExit(f"Input capture not found: {input_path}")

    parsed = parse_pcap_to_jsonl(input_path=input_path, output_path=output_path)
    print(f"parsed_wifi_frames {parsed}")
    print(f"jsonl_output {output_path}")
    return 0

