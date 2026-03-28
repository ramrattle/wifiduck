# Security Policy

## Supported Scope
`wifiduck` is a SQL-first analytics toolkit for offline packet capture analysis. The primary security risks in this repository are:

- unsafe handling of untrusted capture files
- accidental publication of sensitive captures
- shell or path misuse in helper scripts

## Reporting
If you find a vulnerability in the repository code or documentation, open a private security report if your hosting platform supports it. If private reporting is not available, do not publish exploit details together with sensitive sample data.

## Safe Usage Expectations
- Treat all `.pcap` and `.pcapng` files as untrusted input.
- Do not commit customer, employee, or production captures.
- Sanitize captures before sharing them publicly.
- Review sample-data provenance before release.

## Current Hardening
- Helper tooling avoids shell execution for packet parsing.
- Repository paths are resolved relative to the project root instead of using hard-coded absolute paths.
- Public examples are separated from research notes and generated outputs.

