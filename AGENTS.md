# Repository Guidelines

## Project Structure & Module Organization
`sql/` contains the macro pack, split into `sql/core/` and focused files in `sql/macros/`. `examples/sql/` holds runnable playbooks. Public captures, JSONL fixtures, and provenance notes live in `sample-data/`. Python helper code lives in `src/wifiduck_tools/` with CLI wrappers in `tools/`. Keep research notes in `research/` and tests in `tests/`.

## Build, Test, and Development Commands
This repository is SQL-first, with lightweight Python tooling for fixture generation and tests.

```bash
duckdb
```
Start the DuckDB shell, then run:

```sql
INSTALL wireduck FROM community;
LOAD wireduck;
.read sql/wifiduck.sql
```

Run the helper tooling with:

```bash
python tools/open_pcap_analysis.py --input sample-data/pcap/wpa-induction.pcap --output /tmp/wifiduck.jsonl
```

Run regression tests with:

```bash
python -m unittest discover -s tests -v
```

## Coding Style & Naming Conventions
Follow the existing style in each language. SQL macros use uppercase keywords, snake_case identifiers, and the `wd_` prefix for public macros, for example `wd_retry_hotspots_jsonl`. Python uses 4-space indentation, snake_case functions, and repository-relative paths. Keep helper scripts free of shell-outs for packet parsing.

## Testing Guidelines
Use `python -m unittest discover -s tests -v`. SQL changes should add or update a regression case in `tests/test_sql_macros.py` or `tests/test_wifi7_macros.py`. Helper-tool changes should keep `tests/test_tools_smoke.py` green. Prefer deterministic JSONL fixtures for assertions.

## Commit & Pull Request Guidelines
This checkout does not include `.git` history, so no repository-specific commit convention can be inferred locally. Use short, imperative commit subjects such as `Add MLO overview macro`. For pull requests, include: purpose, affected macros or scripts, validation commands run, and provenance notes when adding sample captures.

## Data & Configuration Notes
Prefer small, sanitized captures in `sample-data/pcap/`. Do not commit sensitive packet data, credentials, or environment-specific absolute paths. Record redistribution basis in `sample-data/notes/SOURCES.md` before adding new captures.
