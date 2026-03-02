# <Project Name>

Python package template with `src/` layout, linting, tests, and core-gated CI plus advisory typing checks.

## Status
- Stage: Draft | Active | Stable | Deprecated
- Owner: <Owner>
- License: <License Name>
- Visibility: Public | Private | Internal
- Reason: <Why this visibility level is correct>
- Promotion criteria to Public: <What must be true before public release>

## What This Project Is
- A baseline for maintainable Python services/tools.
- A derived template from `repo-template-base` with Python-specific quality gates.

## Use This Template

1. Click **Use this template** on GitHub to create a new repository.
2. Rename package/module identifiers and update ownership metadata.
3. Review `.env.example` and update environment configuration for your target project.
4. Run validation and CI checks before first release.

## Quickstart

### Prerequisites
- Python 3.10+
- `pip`
- `rg` (ripgrep)

### Install
```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

### Core Checks (Blocking)
```bash
ruff check .
ruff format --check .
pytest -q
```

### Advisory Checks (Non-blocking)
```bash
mypy src
```

### Run
```bash
python -m project_name
```

## Repository Layout
- `src/project_name/` package code
- `tests/` test suite
- `docs/` project documentation and doctrine snapshot
- `examples/` sample usage
- `tools/` helper scripts

## Documentation
- [Overview](docs/overview.md)
- [Architecture](docs/architecture.md)
- [ADRs](docs/adr/)
- [Doctrine Snapshot](docs/doctrine/README.md)

## Validation
```bash
bash tools/validate-template.sh core
bash tools/validate-template.sh advisory
```

## Contributing
See `CONTRIBUTING.md`.
