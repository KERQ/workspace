#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

G2_SSH="${G2_SSH:-g2@192.168.1.19}"
MIGRATE_SCRIPT="${WORKSPACE_ROOT}/scripts/migration/g2-runtime-path-migrate.sh"

deploy_print_help() {
  cat <<EOF
Usage: deploy/scripts/migrate-g2-runtime-path.sh <command> [--apply]

Runs SPEC-005B migration on G2 via SSH.
Commands: preflight | backup | sync | cutover | smoke | rollback

  preflight, backup, sync — no --apply required
  cutover, rollback       — require --apply and APPROVE_DEPLOY=yes
EOF
}

if [[ ! -f "${MIGRATE_SCRIPT}" ]]; then
  echo "ERROR: missing ${MIGRATE_SCRIPT}" >&2
  exit 1
fi

CMD="${1:-}"
shift || true
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
  cutover|rollback)
    if [[ "${DEPLOY_APPLY}" -ne 1 ]]; then
      echo "ERROR: ${CMD} requires --apply" >&2
      exit 2
    fi
    deploy_require_approve
    ;;
esac

echo "=== G2 migrate ${CMD} via ${G2_SSH} ==="
ssh -o BatchMode=yes "${G2_SSH}" "APPROVE_DEPLOY=${APPROVE_DEPLOY:-no} BACKUP_ROOT=${BACKUP_ROOT:-/mnt/seagate/backups/epic-005-g2-runtime-path} bash -s" -- "${CMD}" < "${MIGRATE_SCRIPT}"
