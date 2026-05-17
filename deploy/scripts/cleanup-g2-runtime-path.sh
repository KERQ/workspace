#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

G2_SSH="${G2_SSH:-g2@192.168.1.19}"
CLEANUP_SCRIPT="${WORKSPACE_ROOT}/scripts/migration/g2-runtime-path-cleanup.sh"

deploy_print_help() {
  cat <<EOF
Usage: deploy/scripts/cleanup-g2-runtime-path.sh <command> [--apply]

SPEC-005E G2 cleanup via SSH.
Commands: preflight | archive-bak | remove-symlinks | remove-stale | smoke

Host-changing commands require --apply and APPROVE_DEPLOY=yes.
EOF
}

[[ -f "${CLEANUP_SCRIPT}" ]] || { echo "ERROR: missing ${CLEANUP_SCRIPT}" >&2; exit 1; }

CMD="${1:-}"; shift || true
[[ -n "${CMD}" ]] || { deploy_print_help; exit 2; }

DEPLOY_APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DEPLOY_APPLY=1; shift ;;
    -h|--help) deploy_print_help; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "${CMD}" in
  archive-bak|remove-symlinks|remove-stale)
    [[ "${DEPLOY_APPLY}" -eq 1 ]] || { echo "ERROR: ${CMD} requires --apply" >&2; exit 2; }
    deploy_require_approve
    ;;
esac

echo "=== G2 cleanup ${CMD} via ${G2_SSH} ==="
ssh -o BatchMode=yes "${G2_SSH}" "APPROVE_DEPLOY=${APPROVE_DEPLOY:-no} ARCHIVE_ROOT=${ARCHIVE_ROOT:-/mnt/seagate/backups/epic-005-g2-runtime-path} bash -s" -- "${CMD}" < "${CLEANUP_SCRIPT}"
