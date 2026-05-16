#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
deploy_parse_apply_flag "$@"
DEPLOY_LIMIT=g2
deploy_run_layer homeserver-core playbooks/g2.yml .
echo "G2 core ${DEPLOY_MODE} finished OK"
