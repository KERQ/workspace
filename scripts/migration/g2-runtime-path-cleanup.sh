#!/usr/bin/env bash
# EPIC-005 / SPEC-005E — remove backward symlinks and stale paths on G2
set -euo pipefail

CANON="/opt/homeserver-services"
SYMLINK_REPO="/opt/homeserver-ansible-repo"
SYMLINK_INFISICAL="/opt/homeserver-ansible/infisical"
LEGACY_ROOT="/opt/homeserver-ansible"
LEGACY_G2_CONFIG="${LEGACY_ROOT}/g2-config"
ARCHIVE_ROOT="${ARCHIVE_ROOT:-/mnt/seagate/backups/epic-005-g2-runtime-path}"
TS="${TS:-$(date +%Y%m%d-%H%M%S)}"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

run_priv() {
  if [[ "$(id -u)" -eq 0 ]]; then "$@"; else sudo -n "$@"; fi
}

require_approve_host() {
  [[ "${APPROVE_DEPLOY:-no}" == "yes" ]] || die "host-changing steps require APPROVE_DEPLOY=yes"
}

compose_uses_canon() {
  local bad=0 name
  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    local cfg
    cfg="$(docker inspect "${name}" --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' 2>/dev/null || true)"
    if [[ -n "${cfg}" && "${cfg}" != *"${CANON}"* ]]; then
      log "WARN container ${name} compose config not under ${CANON}: ${cfg}"
      bad=$((bad + 1))
    fi
  done < <(docker ps -q | xargs -r docker inspect --format '{{.Name}}' 2>/dev/null | sed 's#^/##' || true)
  [[ "${bad}" -eq 0 ]]
}

cmd_preflight() {
  log "preflight SPEC-005E cleanup"
  [[ -d "${CANON}/g2-config" ]] || die "missing ${CANON}/g2-config"
  if [[ -L "${SYMLINK_REPO}" ]]; then
    [[ "$(readlink -f "${SYMLINK_REPO}")" == "$(readlink -f "${CANON}")" ]] || die "unexpected repo symlink target"
    log "OK: ${SYMLINK_REPO} is backward symlink"
  elif [[ -e "${SYMLINK_REPO}" ]]; then
    die "${SYMLINK_REPO} exists and is not a symlink — resolve manually"
  else
    log "OK: ${SYMLINK_REPO} already absent"
  fi
  compose_uses_canon || die "some containers still use non-canonical compose paths"
  log "preflight OK"
}

cmd_archive_bak() {
  require_approve_host
  local dest="${ARCHIVE_ROOT}/cleanup-archive-${TS}"
  run_priv mkdir -p "${dest}"
  for d in /opt/homeserver-ansible-repo.bak-* /opt/homeserver-ansible-infisical.bak-*; do
    [[ -e "${d}" ]] || continue
    log "archive ${d} -> ${dest}/"
    run_priv cp -a "${d}" "${dest}/"
    run_priv rm -rf "${d}"
  done
  log "archive-bak OK: ${dest}"
}

cmd_remove_symlinks() {
  require_approve_host
  compose_uses_canon || die "refusing to remove symlinks — compose not on ${CANON}"
  if [[ -L "${SYMLINK_REPO}" ]]; then
    run_priv rm -f "${SYMLINK_REPO}"
    log "removed ${SYMLINK_REPO}"
  fi
  if [[ -L "${SYMLINK_INFISICAL}" ]]; then
    run_priv rm -f "${SYMLINK_INFISICAL}"
    log "removed ${SYMLINK_INFISICAL}"
  fi
  [[ -d "${CANON}" ]] || die "canonical path missing after symlink removal"
  log "remove-symlinks OK"
}

cmd_remove_stale() {
  require_approve_host
  if [[ -d "${LEGACY_G2_CONFIG}" && ! -L "${LEGACY_G2_CONFIG}" ]]; then
    local dest="${ARCHIVE_ROOT}/cleanup-stale-g2-config-${TS}"
    run_priv mkdir -p "${dest}"
    log "archive stale ${LEGACY_G2_CONFIG}"
    run_priv cp -a "${LEGACY_G2_CONFIG}" "${dest}/"
    run_priv rm -rf "${LEGACY_G2_CONFIG}"
  fi
  if [[ -d "${LEGACY_ROOT}" ]] && [[ -z "$(ls -A "${LEGACY_ROOT}" 2>/dev/null || true)" ]]; then
    run_priv rmdir "${LEGACY_ROOT}" 2>/dev/null || log "WARN: ${LEGACY_ROOT} not empty, left in place"
  fi
  log "remove-stale OK"
}

cmd_smoke() {
  log "smoke after cleanup"
  [[ -d "${CANON}/g2-config" ]] || die "missing canon"
  [[ ! -e "${SYMLINK_REPO}" ]] && log "OK: repo symlink gone" || log "WARN: ${SYMLINK_REPO} still exists"
  curl -fsS -o /dev/null --max-time 8 http://127.0.0.1/airflow/health && log "PASS airflow" || log "WARN airflow"
  curl -fsS -o /dev/null --max-time 8 http://127.0.0.1:19000/minio/health/live && log "PASS minio" || log "WARN minio"
  if [[ -x "${CANON}/scripts/trading/smoke.sh" ]]; then
    HOMESERVER_RUNTIME_ROOT="${CANON}" bash "${CANON}/scripts/trading/smoke.sh" || log "WARN trading smoke"
  fi
  log "smoke finished"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  preflight       Verify compose uses ${CANON}; safe anytime
  archive-bak     Move /opt/*.bak-* to ${ARCHIVE_ROOT} (APPROVE_DEPLOY=yes)
  remove-symlinks Remove backward symlinks (APPROVE_DEPLOY=yes)
  remove-stale    Archive/remove stale ${LEGACY_G2_CONFIG} (APPROVE_DEPLOY=yes)
  smoke           Health checks after cleanup

Full sequence: preflight → archive-bak → remove-symlinks → remove-stale → smoke
EOF
}

main() {
  case "${1:-}" in
    preflight) cmd_preflight ;;
    archive-bak) cmd_archive_bak ;;
    remove-symlinks) cmd_remove_symlinks ;;
    remove-stale) cmd_remove_stale ;;
    smoke) cmd_smoke ;;
    -h|--help|"") usage ;;
    *) die "unknown command: $1" ;;
  esac
}

main "$@"
