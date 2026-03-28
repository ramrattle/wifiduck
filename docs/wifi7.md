# Wi-Fi 7 Coverage

`wifiduck` treats Wi-Fi 7 support as observable-first. The SQL layer only exposes fields that are likely to appear in dissector output and degrades safely when they are absent.

## Current focus
- Multi-Link Operation visibility through MLD address and link-id fields
- 6 GHz detection and wide-channel observation
- Basic EHT STA profile count exposure when available

## Included example playbooks
- `examples/sql/wifi7_playbook.sql`: overview queries, per-link inventory, link imbalance, channel spread, and MLO timeline inspection
- `examples/sql/wifi7_link_diagnostics.sql`: focused link-health and band-consistency checks
- `examples/sql/wifi7_real_world_cases.sql`: staged triage, session proof, and pre-association retry-loop detection
- `cases/wifi7-mlo-auth-loop/`: case pack for an MLO-era first-attempt authentication loop

## Important limits
- Field availability depends on the capture NIC, driver, radiotap metadata, and dissector support.
- Publicly downloadable Wi-Fi 7 captures are still scarce.
- The bundled Wi-Fi 7 examples use JSONL fixtures that mirror expected field layout; contributors should replace them with redistributable real captures as they become available.
