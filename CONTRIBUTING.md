# Contributing

## Branching Strategy
- `master` stable branch
- Feature branches: `feat/<topic>`
- Fix branches: `fix/<topic>`

## Pull Requests
- Keep changes focused
- Prefer small PRs
- Update docs when behavior or structure changes

## Commit Message Format
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `chore:` maintenance
- `refactor:` internal changes without behavior change

## Commit Signing
- Signed commits are required for release and protected branches.
- Verify local signing is configured before pushing.

## Code Quality
- Core-gated checks (blocking):
  - `ruff check .`
  - `ruff format --check .`
  - `pytest -q`
- Advisory checks (non-blocking):
  - `mypy src`
- Template integrity checks:
  - `bash tools/validate-template.sh core`
  - `bash tools/validate-template.sh advisory`
