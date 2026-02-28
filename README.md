# <Project Name>

Python package template with `src/` layout, linting, typing, tests, and CI.

## Status
- Stage: Draft | Active | Stable | Deprecated
- Owner: <Owner>
- License: <License Name>
- Visibility: Public | Private | Internal
- Reason: <Why this visibility level is correct>
- Promotion criteria to Public: <What must be true before public release>

## What This Project Is
- A baseline for maintainable Python services/tools.
- Not a full framework or batteries-included product scaffold.

## Quickstart

### Prerequisites
- Python 3.10+
- `pip`

### Install, Lint, Type-check, Test
```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
ruff check .
ruff format --check .
mypy src
pytest -q
```

### Run
```bash
python -m project_name
```

## Repository Layout
- `src/project_name/` package code
- `tests/` test suite
- `docs/` project documentation
- `examples/` sample usage
- `tools/` helper scripts

## Documentation
- [Overview](docs/overview.md)
- [Architecture](docs/architecture.md)
- [ADRs](docs/adr/)

## Contributing
See `CONTRIBUTING.md`.
