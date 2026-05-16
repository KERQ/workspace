#!/usr/bin/env bash
# EPIC-005 / SPEC-005B — migrate G2 runtime paths to /opt/homeserver-services
# Run on G2 (g2@192.168.1.19) or via: ssh g2@192.168.1.19 'bash -s' < g2-runtime-path-migrate.sh -- preflight
set -euo pipefail

SOURCE_REPO="/opt/homeserver-ansible-repo"
SOURCE_LEGACY="/opt/homeserver-ansible"
SOURCE_INFISICAL="${SOURCE_LEGACY}/infisical"
TARGET_ROOT="/opt/homeserver-services"
TARGET_INFISICAL="${TARGET_ROOT}/infisical"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/seagate/backups/epic-005-g2-runtime-path}"
TS="${TS:-$(date +%Y%m%d-%H%M%S)}"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

run_priv() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo -n "$@"
  fi
}

ensure_target_root() {
  if [[ ! -d "${TARGET_ROOT}" ]]; then
    run_priv mkdir -p "${TARGET_ROOT}"
    run_priv chown g2:g2 "${TARGET_ROOT}"
  fi
}

# G2 may not have rsync installed; cp -a is sufficient for small config trees.
sync_tree() {
  local src="${1%/}/" dest="$2"
  mkdir -p "${dest}"
  if command -v rsync >/dev/null 2>&1; then
    if [[ "${SYNC_DELETE:-0}" == "1" ]]; then
      rsync -a --delete "${src}" "${dest}/"
    else
      rsync -a "${src}" "${dest}/"
    fi
  else
    if [[ "${SYNC_DELETE:-0}" == "1" && -d "${dest}" ]]; then
      find "${dest}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    fi
    # shellcheck disable=SC2086
    cp -a "${src}"* "${dest}/" 2>/dev/null || true
    # Dotfiles (.env etc.) — glob * skips them
    shopt -s dotglob nullglob
    for f in "${src}".*; do
      [[ -e "${f}" ]] || continue
      base="$(basename "${f}")"
      [[ "${base}" == "." || "${base}" == ".." ]] && continue
      cp -a "${f}" "${dest}/"
    done
    shopt -u dotglob nullglob
  fi
}

require_root_or_g2() {
  [[ "$(id -un)" == "g2" || "$(id -un)" == "root" ]] || die "run as g2 or root on G2"
}

require_approve_cutover() {
  [[ "${APPROVE_DEPLOY:-no}" == "yes" ]] || die "cutover/smoke-after-cutover require APPROVE_DEPLOY=yes"
}

path_is_symlink_to() {
  local path="$1" expected="$2"
  [[ -L "${path}" ]] && [[ "$(readlink -f "${path}")" == "$(readlink -f "${expected}")" ]]
}

cmd_preflight() {
  require_root_or_g2
  log "preflight G2 runtime path migration"
  for p in "${SOURCE_REPO}" "${SOURCE_LEGACY}"; do
    [[ -d "${p}" ]] || die "missing ${p}"
    [[ -L "${p}" ]] && die "${p} is already a symlink — investigate before continuing"
  done
  if [[ -e "${TARGET_ROOT}" ]]; then
    if path_is_symlink_to "${SOURCE_REPO}" "${TARGET_ROOT}"; then
      log "OK: ${SOURCE_REPO} already symlinks to ${TARGET_ROOT}"
    elif [[ -d "${TARGET_ROOT}" ]]; then
      log "OK: ${TARGET_ROOT} exists (sync may have run)"
    else
      die "${TARGET_ROOT} exists but is not a directory"
    fi
  else
    log "OK: ${TARGET_ROOT} absent (expected before first sync)"
  fi
  [[ -d "${SOURCE_INFISICAL}" ]] || die "missing ${SOURCE_INFISICAL}"
  docker ps --format '{{.Names}}' | head -5 >/dev/null 2>&1 || die "docker not available"
  log "docker compose projects using ${SOURCE_REPO}:"
  docker ps --format '{{.Label "com.docker.compose.project.config_files"}}' 2>/dev/null \
    | grep -F "${SOURCE_REPO}" | sort -u | head -10 || true
  du -sh "${SOURCE_REPO}" "${SOURCE_LEGACY}" 2>/dev/null || true
  log "preflight OK"
}

cmd_backup() {
  require_root_or_g2
  local dest="${BACKUP_ROOT}/${TS}"
  log "backup to ${dest}"
  mkdir -p "${dest}"
  sync_tree "${SOURCE_REPO}" "${dest}/homeserver-ansible-repo"
  sync_tree "${SOURCE_LEGACY}" "${dest}/homeserver-ansible"
  echo "${TS}" > "${dest}/.backup-timestamp"
  log "backup OK: ${dest}"
}

cmd_sync() {
  require_root_or_g2
  log "sync → ${TARGET_ROOT} (services keep using ${SOURCE_REPO} until cutover)"
  ensure_target_root
  SYNC_DELETE=1 sync_tree "${SOURCE_REPO}" "${TARGET_ROOT}"
  mkdir -p "${TARGET_INFISICAL}"
  sync_tree "${SOURCE_INFISICAL}" "${TARGET_INFISICAL}"
  log "sync OK"
  du -sh "${TARGET_ROOT}" "${TARGET_INFISICAL}"
}

compose_down_all() {
  local d
  for d in \
    "${SOURCE_REPO}/g2-config" \
    "${SOURCE_REPO}/g2-config/airflow" \
    "${SOURCE_REPO}/g2-config/minio" \
    "${SOURCE_REPO}/g2-config/jupyter" \
    "${SOURCE_REPO}/g2-config/plane" \
    "${SOURCE_INFISICAL}"; do
    if [[ -f "${d}/docker-compose.yml" ]]; then
      log "compose down: ${d}"
      (cd "${d}" && docker compose down) || true
    fi
  done
}

compose_up_all() {
  local d
  for d in \
    "${SOURCE_INFISICAL}" \
    "${SOURCE_REPO}/g2-config" \
    "${SOURCE_REPO}/g2-config/minio" \
    "${SOURCE_REPO}/g2-config/airflow" \
    "${SOURCE_REPO}/g2-config/jupyter" \
    "${SOURCE_REPO}/g2-config/plane"; do
    if [[ -f "${d}/docker-compose.yml" ]]; then
      log "compose up: ${d}"
      (cd "${d}" && docker compose up -d) || die "compose up failed: ${d}"
    fi
  done
}

cmd_cutover() {
  require_root_or_g2
  require_approve_cutover
  [[ -d "${TARGET_ROOT}/g2-config" ]] || die "run sync first"
  [[ -d "${TARGET_INFISICAL}" ]] || die "run sync first (infisical)"
  [[ -L "${SOURCE_REPO}" ]] && die "${SOURCE_REPO} already symlinked"

  local bak_repo="/opt/homeserver-ansible-repo.bak-${TS}"
  local bak_infisical="/opt/homeserver-ansible-infisical.bak-${TS}"

  log "cutover: brief downtime — stopping compose stacks"
  compose_down_all

  log "final sync"
  SYNC_DELETE=1 sync_tree "${SOURCE_REPO}" "${TARGET_ROOT}"
  sync_tree "${SOURCE_INFISICAL}" "${TARGET_INFISICAL}"

  log "swap ${SOURCE_REPO} → symlink"
  run_priv mv "${SOURCE_REPO}" "${bak_repo}"
  run_priv ln -sfn "${TARGET_ROOT}" "${SOURCE_REPO}"
  run_priv chown -h g2:g2 "${SOURCE_REPO}" 2>/dev/null || true

  log "swap ${SOURCE_INFISICAL} → symlink"
  run_priv mv "${SOURCE_INFISICAL}" "${bak_infisical}"
  run_priv ln -sfn "${TARGET_INFISICAL}" "${SOURCE_INFISICAL}"
  run_priv chown -h g2:g2 "${SOURCE_INFISICAL}" 2>/dev/null || true

  if [[ ! -f "${TARGET_INFISICAL}/.env" && -f "${bak_infisical}/.env" ]]; then
    log "restore infisical dotfiles from backup (cp without dotglob misses .env)"
    cp -a "${bak_infisical}/." "${TARGET_INFISICAL}/"
  fi

  log "backups of replaced dirs: ${bak_repo} ${bak_infisical}"
  log "starting stacks via backward symlinks"
  compose_up_all

  log "cutover OK — verify with: $0 smoke"
}

cmd_smoke() {
  require_root_or_g2
  log "smoke checks (paths + HTTP)"
  readlink -f "${SOURCE_REPO}" | grep -q "${TARGET_ROOT}" || die "${SOURCE_REPO} not pointing at ${TARGET_ROOT}"
  [[ -f "${SOURCE_REPO}/g2-config/docker-compose.yml" ]] || die "missing compose via symlink"
  curl -fsS -o /dev/null --max-time 5 http://127.0.0.1:4000/health/liveliness 2>/dev/null \
    && log "PASS litellm" || log "WARN litellm health"
  curl -fsS -o /dev/null --max-time 5 http://127.0.0.1/airflow/health 2>/dev/null \
    && log "PASS airflow" || log "WARN airflow health"
  curl -fsS -o /dev/null --max-time 5 http://127.0.0.1:19000/minio/health/live 2>/dev/null \
    && log "PASS minio" || log "WARN minio health"
  if [[ -x "${SOURCE_REPO}/scripts/trading/smoke.sh" ]]; then
    HOMESERVER_RUNTIME_ROOT="${SOURCE_REPO}" bash "${SOURCE_REPO}/scripts/trading/smoke.sh" || log "WARN trading smoke"
  fi
  log "smoke finished"
}

cmd_rollback() {
  require_root_or_g2
  require_approve_cutover
  local bak_repo bak_infisical
  bak_repo="$(ls -dt /opt/homeserver-ansible-repo.bak-* 2>/dev/null | head -1 || true)"
  bak_infisical="$(ls -dt /opt/homeserver-ansible-infisical.bak-* 2>/dev/null | head -1 || true)"
  [[ -n "${bak_repo}" ]] || die "no repo backup dir found"

  compose_down_all

  if [[ -L "${SOURCE_REPO}" ]]; then
    run_priv rm -f "${SOURCE_REPO}"
    run_priv mv "${bak_repo}" "${SOURCE_REPO}"
  fi
  if [[ -L "${SOURCE_INFISICAL}" && -n "${bak_infisical}" ]]; then
    run_priv rm -f "${SOURCE_INFISICAL}"
    run_priv mv "${bak_infisical}" "${SOURCE_INFISICAL}"
  fi

  compose_up_all
  log "rollback OK — restored ${SOURCE_REPO}"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  preflight   Read-only checks (safe anytime)
  backup      Rsync sources to ${BACKUP_ROOT}/<timestamp>
  sync        Copy to ${TARGET_ROOT} without stopping Docker
  cutover     Stop stacks, symlink old paths → new (needs APPROVE_DEPLOY=yes)
  smoke       Health checks after cutover
  rollback    Restore .bak-* dirs (needs APPROVE_DEPLOY=yes)

Env:
  APPROVE_DEPLOY=yes   Required for cutover and rollback
  BACKUP_ROOT          Default: ${BACKUP_ROOT}
  TS                   Backup/cutover timestamp suffix
EOF
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    preflight) cmd_preflight ;;
    backup) cmd_backup ;;
    sync) cmd_sync ;;
    cutover) cmd_cutover ;;
    smoke) cmd_smoke ;;
    rollback) cmd_rollback ;;
    -h|--help|"") usage ;;
    *) die "unknown command: ${cmd}" ;;
  esac
}

main "$@"
