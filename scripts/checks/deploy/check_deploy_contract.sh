#!/usr/bin/env bash
# Verify deploy scripts and contracts/deploy order stay aligned (EPIC-002).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${ROOT}"

ERRORS=0
err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
ok() { echo "OK: $*"; }

require_file() {
  [[ -f "$1" ]] || { err "missing $1"; return; }
  ok "file $1"
}

echo "=== Deploy tree ==="
require_file deploy/README.md
require_file deploy/inventory/hosts.yml
require_file deploy/docs/deploy-boundaries.md
require_file deploy/lib/common.sh

for s in deploy-t630-full.sh deploy-g2-full.sh \
  deploy-t630-core.sh deploy-t630-life.sh deploy-t630-services.sh \
  deploy-g2-core.sh deploy-g2-services.sh; do
  require_file "deploy/scripts/${s}"
  [[ -x "deploy/scripts/${s}" ]] || err "not executable: deploy/scripts/${s}"
done

echo "=== Contracts ==="
require_file contracts/deploy/t630-deploy-order.yml
require_file contracts/deploy/g2-deploy-order.yml

echo "=== T630 order in full script ==="
T630_SCRIPT="deploy/scripts/deploy-t630-full.sh"
grep -q 'homeserver-core' "${T630_SCRIPT}" && ok "t630 full mentions core"
grep -q 'life-platform' "${T630_SCRIPT}" && ok "t630 full mentions life"
grep -q 'homeserver-services' "${T630_SCRIPT}" && ok "t630 full mentions services"

# core before life before services in file
core_line=$(grep -n 'homeserver-core' "${T630_SCRIPT}" | head -1 | cut -d: -f1)
life_line=$(grep -n 'life-platform' "${T630_SCRIPT}" | head -1 | cut -d: -f1)
svc_line=$(grep -n 'homeserver-services' "${T630_SCRIPT}" | head -1 | cut -d: -f1)
if [[ "${core_line}" -lt "${life_line}" && "${life_line}" -lt "${svc_line}" ]]; then
  ok "t630 layer order core < life < services"
else
  err "t630 layer order wrong in ${T630_SCRIPT}"
fi

echo "=== G2 order in full script ==="
G2_SCRIPT="deploy/scripts/deploy-g2-full.sh"
grep -q 'homeserver-core' "${G2_SCRIPT}" && ok "g2 full mentions core"
grep -q 'homeserver-services' "${G2_SCRIPT}" && ok "g2 full mentions services"
grep -q 'life-platform' "${G2_SCRIPT}" && err "g2 full must not deploy life-platform" || ok "g2 full skips life-platform"

core_line=$(grep -n 'homeserver-core' "${G2_SCRIPT}" | head -1 | cut -d: -f1)
svc_line=$(grep -n 'homeserver-services' "${G2_SCRIPT}" | head -1 | cut -d: -f1)
if [[ "${core_line}" -lt "${svc_line}" ]]; then
  ok "g2 layer order core < services"
else
  err "g2 layer order wrong in ${G2_SCRIPT}"
fi

echo "=== Apply gate ==="
grep -q 'APPROVE_DEPLOY' deploy/lib/common.sh && ok "APPROVE_DEPLOY gate in common.sh"

echo "=== Summary ==="
echo "Errors: ${ERRORS}"
[[ "${ERRORS}" -eq 0 ]] || exit 1
