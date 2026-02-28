#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-all}"

usage() {
  cat <<'USAGE'
Usage: bash tools/validate-template.sh [core|advisory|all]

Modes:
  core      Run blocking template and Python checks
  advisory  Run non-blocking deep checks (including mypy)
  all       Run both (default)
USAGE
}

if [[ "$MODE" != "core" && "$MODE" != "advisory" && "$MODE" != "all" ]]; then
  usage
  exit 2
fi

core_errors=0
advisory_warnings=0

core_fail() {
  echo "[core][err] $*"
  core_errors=$((core_errors + 1))
}

advisory_warn() {
  echo "[advisory][warn] $*"
  advisory_warnings=$((advisory_warnings + 1))
}

require_file() {
  local rel="$1"
  if [[ ! -f "$ROOT_DIR/$rel" ]]; then
    core_fail "Missing required file: $rel"
  fi
}

require_heading() {
  local rel="$1"
  local pattern="$2"
  if [[ ! -f "$ROOT_DIR/$rel" ]]; then
    core_fail "Missing required file: $rel"
    return
  fi
  if ! rg -q "$pattern" "$ROOT_DIR/$rel"; then
    core_fail "Missing required heading pattern '${pattern}' in $rel"
  fi
}

run_core_command() {
  local label="$1"
  shift
  if ! "$@"; then
    core_fail "Command failed (${label}): $*"
  fi
}

check_required_files() {
  local files=(
    "AGENTS.md"
    "AI_CONTEXT.md"
    "CONTRIBUTING.md"
    "REPO_POLICY.md"
    "README.md"
    "pyproject.toml"
    "ruff.toml"
    "mypy.ini"
    "src/project_name/__init__.py"
    "src/project_name/__main__.py"
    "tests/test_smoke.py"
    "docs/overview.md"
    "docs/architecture.md"
    "docs/adr/0001-template.md"
    "docs/doctrine/README.md"
    "docs/doctrine/coding.md"
    "docs/doctrine/doctrine-governance.md"
    "docs/doctrine/identity.md"
    "docs/doctrine/naming.md"
    "docs/doctrine/project-standards.md"
    "docs/doctrine/repo-management.md"
    "docs/doctrine/templates/doctrine-change-record-template.md"
    "docs/doctrine/templates/repo-visibility-note-template.md"
    ".github/ISSUE_TEMPLATE/bug_report.md"
    ".github/ISSUE_TEMPLATE/feature_request.md"
    ".github/PULL_REQUEST_TEMPLATE.md"
    ".github/workflows/ci-python.yml"
    "tools/validate-template.sh"
  )

  local rel
  for rel in "${files[@]}"; do
    require_file "$rel"
  done
}

check_doc_structure() {
  require_heading "README.md" "^## Status$"
  require_heading "README.md" "^## Quickstart$"
  require_heading "README.md" "^## Documentation$"
  require_heading "README.md" "^## Validation$"
  require_heading "docs/overview.md" "^# Overview$"
  require_heading "docs/overview.md" "^## Purpose$"
  require_heading "docs/architecture.md" "^# Architecture$"
  require_heading "docs/adr/0001-template.md" "^# ADR 0001:"
}

check_markdown_parse_sanity() {
  local rel
  while IFS= read -r rel; do
    if [[ ! -s "$ROOT_DIR/$rel" ]]; then
      core_fail "Markdown file is empty: $rel"
      continue
    fi
    if ! rg -q '^#' "$ROOT_DIR/$rel"; then
      core_fail "Markdown file has no heading: $rel"
    fi
  done < <(cd "$ROOT_DIR" && rg --files -g '*.md')
}

check_local_markdown_links() {
  local rel
  while IFS= read -r rel; do
    if [[ "$rel" == docs/doctrine/* ]]; then
      continue
    fi
    local file="$ROOT_DIR/$rel"
    local target
    while IFS= read -r target; do
      [[ -z "$target" ]] && continue
      target="${target%% *}"
      target="${target#<}"
      target="${target%>}"

      case "$target" in
        http://*|https://*|mailto:*|\#*)
          continue
          ;;
      esac

      local path_only="${target%%#*}"
      [[ -z "$path_only" ]] && continue

      local resolved
      if [[ "$path_only" == /* ]]; then
        resolved="$ROOT_DIR/${path_only#/}"
      else
        resolved="$(dirname "$file")/$path_only"
      fi

      if [[ ! -e "$resolved" ]]; then
        advisory_warn "Broken local markdown link in $rel -> $target"
      fi
    done < <(grep -oE '\[[^][]+\]\([^)]*\)' "$file" | sed -E 's/^[^()]*\(([^)]*)\)$/\1/' || true)
  done < <(cd "$ROOT_DIR" && rg --files -g '*.md')
}

is_allowed_placeholder_line() {
  local line="$1"
  local pattern
  local allowed_patterns=(
    '^README\.md:[0-9]+:# <Project Name>$'
    '^README\.md:[0-9]+:- Owner: <Owner>$'
    '^README\.md:[0-9]+:- License: <License Name>$'
    '^README\.md:[0-9]+:- Reason: <Why this visibility level is correct>$'
    '^README\.md:[0-9]+:- Promotion criteria to Public: <What must be true before public release>$'
    '^REPO_POLICY\.md:[0-9]+:- Reason: <Required; explain why this level is correct>$'
    '^REPO_POLICY\.md:[0-9]+:- Promotion criteria to Public: <Required; concrete quality/security gates>$'
  )

  for pattern in "${allowed_patterns[@]}"; do
    if [[ "$line" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

is_allowed_generic_line() {
  local line="$1"
  local pattern
  local allowed_patterns=(
    '^docs/overview\.md:[0-9]+:Describe what the system/tool/application does at a high level\.$'
    '^docs/overview\.md:[0-9]+:[[:space:]-]*Key capability [0-9]+$'
  )

  for pattern in "${allowed_patterns[@]}"; do
    if [[ "$line" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

check_placeholders() {
  local matches
  local filtered=()
  local line

  matches="$(cd "$ROOT_DIR" && rg -n "<[^>]+>" README.md REPO_POLICY.md docs/overview.md docs/architecture.md docs/adr 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if is_allowed_placeholder_line "$line"; then
        continue
      fi
      filtered+=("$line")
    done <<< "$matches"
  fi

  if [[ ${#filtered[@]} -gt 0 ]]; then
    advisory_warn "Found unresolved angle-bracket placeholders"
    printf '%s\n' "${filtered[@]}"
  fi

  filtered=()
  matches="$(cd "$ROOT_DIR" && rg -n "(Describe what|Key capability [0-9]+|Item [0-9]+)" README.md docs/overview.md docs/architecture.md docs/adr CONTRIBUTING.md 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if is_allowed_generic_line "$line"; then
        continue
      fi
      filtered+=("$line")
    done <<< "$matches"
  fi

  if [[ ${#filtered[@]} -gt 0 ]]; then
    advisory_warn "Found generic template placeholder text"
    printf '%s\n' "${filtered[@]}"
  fi
}

run_python_core_checks() {
  if ! command -v ruff >/dev/null 2>&1; then
    core_fail "ruff is not installed"
    return
  fi
  if ! command -v pytest >/dev/null 2>&1; then
    core_fail "pytest is not installed"
    return
  fi

  run_core_command "ruff-check" ruff check .
  run_core_command "ruff-format" ruff format --check .
  run_core_command "pytest" pytest -q
}

run_python_advisory_checks() {
  if ! command -v mypy >/dev/null 2>&1; then
    advisory_warn "mypy is not installed; skipping advisory type check"
    return
  fi

  if ! mypy src; then
    advisory_warn "mypy reported typing findings"
  fi
}

run_core() {
  echo "== Core Validation (blocking) =="
  check_required_files
  check_doc_structure
  check_markdown_parse_sanity
  run_python_core_checks

  if [[ $core_errors -gt 0 ]]; then
    echo "Core validation failed with ${core_errors} issue(s)."
    return 1
  fi

  echo "Core validation passed."
}

run_advisory() {
  echo "== Advisory Validation (non-blocking) =="
  check_local_markdown_links
  check_placeholders
  run_python_advisory_checks

  if [[ $advisory_warnings -gt 0 ]]; then
    echo "Advisory validation found ${advisory_warnings} warning(s)."
  else
    echo "Advisory validation passed without warnings."
  fi
}

cd "$ROOT_DIR"

case "$MODE" in
  core)
    run_core
    ;;
  advisory)
    run_advisory
    ;;
  all)
    run_core
    run_advisory
    ;;
esac
