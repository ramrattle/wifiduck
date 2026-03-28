# Contributing

## Development
Create a virtual environment, install the helper dependencies, and run the test suite:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
python -m unittest discover -s tests -v
```

## SQL Changes
- Keep public macros under the `wd_` prefix.
- Add new macros in the most focused file under `sql/macros/`.
- If a macro changes behavior, add or update a regression test in `tests/`.

## Sample Data
- Only add captures with clear redistribution rights.
- Record provenance, upstream URL, and trimming notes in `sample-data/notes/SOURCES.md`.
- Never commit private packet captures or secrets.

## Pull Requests
Include:
- the problem being solved
- files or macros affected
- tests run
- sample output if query behavior changed

