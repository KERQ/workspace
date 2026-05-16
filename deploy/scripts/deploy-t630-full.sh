#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

deploy_print_help() {
  cat <<EOF
Usage: deploy/scripts/deploy-t630-full.sh [--apply]

Full T630 deploy order (core -> life -> services).
Default: syntax-check only. Apply requires APPROVE_DEPLOY=yes.
EOF
}

deploy_parse_apply_flag "$@"
DEPLOY_LIMIT=t630

deploy_run_layer homeserver-core playbooks/t630.yml .
deploy_run_layer life-platform playbooks/t630.yml domains/home/ansible
deploy_run_layer homeserver-services playbooks/t630.yml .

echo "T630 full ${DEPLOY_MODE} finished OK"
