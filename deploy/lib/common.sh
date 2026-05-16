# Shared helpers for workspace deploy orchestration (EPIC-002).
# Source from deploy/scripts/*.sh — do not execute directly.

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

deploy_repo_path() {
  local repo_name="$1"
  if [[ ! -e "${WORKSPACE_ROOT}/${repo_name}" ]]; then
    echo "ERROR: repo not found: ${WORKSPACE_ROOT}/${repo_name}" >&2
    return 1
  fi
  (cd "${WORKSPACE_ROOT}/${repo_name}" && pwd -P)
}

deploy_require_approve() {
  if [[ "${APPROVE_DEPLOY:-no}" != "yes" ]]; then
    echo "ERROR: real deploy requires APPROVE_DEPLOY=yes" >&2
    echo "Run without --apply for syntax-check only." >&2
    exit 2
  fi
}

# deploy_run_layer <repo> <playbook> [working_dir_relative]
deploy_run_layer() {
  local repo="$1"
  local playbook="$2"
  local workdir="${3:-.}"
  local mode="${DEPLOY_MODE:-syntax-check}"
  local limit="${DEPLOY_LIMIT:-}"

  local repo_path
  repo_path="$(deploy_repo_path "${repo}")" || return 1

  echo "=== ${repo} (${mode}) dir=${workdir} playbook=${playbook} ==="
  (
    cd "${repo_path}/${workdir}"
    local args=("${playbook}")
    if [[ -n "${limit}" ]]; then
      args+=(-l "${limit}")
    fi
    case "${mode}" in
      syntax-check)
        ansible-playbook --syntax-check "${args[@]}"
        ;;
      apply)
        ansible-playbook "${args[@]}"
        ;;
      *)
        echo "ERROR: unknown DEPLOY_MODE=${mode}" >&2
        exit 2
        ;;
    esac
  )
}

deploy_parse_apply_flag() {
  DEPLOY_APPLY=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply)
        DEPLOY_APPLY=1
        shift
        ;;
      -h|--help)
        deploy_print_help
        exit 0
        ;;
      *)
        echo "ERROR: unknown argument: $1" >&2
        deploy_print_help
        exit 2
        ;;
    esac
  done
  if [[ "${DEPLOY_APPLY}" -eq 1 ]]; then
    deploy_require_approve
    DEPLOY_MODE=apply
  else
    DEPLOY_MODE=syntax-check
    echo "Mode: syntax-check only (pass --apply with APPROVE_DEPLOY=yes for real deploy)"
  fi
}
