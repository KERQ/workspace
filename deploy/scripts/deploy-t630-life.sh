#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
deploy_parse_apply_flag "$@"
DEPLOY_LIMIT=t630
deploy_run_layer life-platform playbooks/t630.yml domains/home/ansible
echo "T630 life ${DEPLOY_MODE} finished OK"
