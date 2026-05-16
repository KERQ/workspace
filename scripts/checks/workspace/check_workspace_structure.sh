#!/usr/bin/env bash
# Workspace structure consistency check (SPEC-002).
# Does not read secret values or recurse into domain repos.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

ERRORS=0
WARNINGS=0

err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $*" >&2; WARNINGS=$((WARNINGS + 1)); }
ok() { echo "OK: $*"; }

require_file() {
  if [[ -f "$1" ]]; then
    ok "file $1"
  else
    err "missing file: $1"
  fi
}

require_dir() {
  if [[ -d "$1" ]]; then
    ok "dir $1"
  else
    err "missing dir: $1"
  fi
}

echo "=== Workspace root files ==="
require_file PROJEKT.md
require_file BACKLOG.md
require_file AGENTS.md
require_file README.md

echo "=== Required directories ==="
require_dir specs
require_dir contracts
require_dir docs/adr
require_dir docs/runbooks
require_dir scripts/checks

echo "=== Templates ==="
require_file specs/SPEC-000-template.md
require_file specs/epics/EPIC-000-template.md
require_file docs/adr/ADR-000-template.md

echo "=== Contracts MVP ==="
require_file contracts/deploy/t630-deploy-order.yml
require_file contracts/deploy/g2-deploy-order.yml
require_file contracts/ansible/role-ownership.yml
require_file contracts/services/ports.yml
require_file contracts/secrets/scopes.yml
require_file contracts/repos/repositories.yml

echo "=== Domain repo symlinks ==="
DOMAIN_REPOS=(
  homeserver-core
  homeserver-services
  life-platform
  investment-research
  openclaw-control-plane
)

for name in "${DOMAIN_REPOS[@]}"; do
  if [[ ! -L "$name" ]]; then
    err "not a symlink: $name"
    continue
  fi
  target="$(readlink "$name")"
  ok "symlink $name -> $target"
  resolved="${ROOT}/${name}"
  if [[ -d "${resolved}/.git" ]]; then
    ok "symlink target has .git: $name"
  else
    err "symlink target missing .git: $name (resolved: ${resolved})"
  fi
done

echo "=== repositories.yml (5 repos) ==="
REPOS_YML="contracts/repos/repositories.yml"
if [[ -f "$REPOS_YML" ]]; then
  for name in "${DOMAIN_REPOS[@]}"; do
    if grep -qE "^[[:space:]]{2}${name}:" "$REPOS_YML"; then
      ok "repositories.yml lists $name"
    else
      err "repositories.yml missing repo key: $name"
    fi
  done
else
  err "missing $REPOS_YML"
fi

echo "=== Obvious secrets in workspace root (names only, maxdepth 1) ==="
shopt -s nullglob
for pattern in .env .env.* *.pem *.key *.p12 *.pfx id_rsa id_ed25519 credentials.json token.json *.token; do
  for f in $pattern; do
    [[ -e "$f" ]] || continue
    case "$f" in
      .env.example) continue ;;
    esac
    err "suspicious file in workspace root: $f"
  done
done

for f in *; do
  [[ -e "$f" ]] || continue
  [[ -f "$f" ]] || continue
  case "$f" in
    *.md|*.yml|*.yaml) continue ;;
  esac
  base="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"
  if [[ "$base" == *credentials* ]] || [[ "$base" == *token* ]]; then
    err "suspicious filename in workspace root: $f"
  fi
done
shopt -u nullglob

echo "=== Summary ==="
echo "Errors: $ERRORS  Warnings: $WARNINGS"
if [[ "$ERRORS" -gt 0 ]]; then
  exit 1
fi
exit 0
