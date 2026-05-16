#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

deploy_print_help() {
  cat <<EOF
Usage: deploy/scripts/deploy-g2-full.sh [--apply]

Full G2 deploy order (core -> services).
Default: syntax-check only. Apply requires APPROVE_DEPLOY=yes.
EOF
}

deploy_parse_apply_flag "$@"
DEPLOY_LIMIT=g2

deploy_run_layer homeserver-core playbooks/g2.yml .
deploy_run_layer homeserver-services playbooks/g2.yml .

echo "G2 full ${DEPLOY_MODE} finished OK"
