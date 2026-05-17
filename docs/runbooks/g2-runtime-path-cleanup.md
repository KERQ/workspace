# Runbook: cleanup ścieżek runtime G2 (SPEC-005E)

**Host:** `g2@192.168.1.19`  
**Po:** [SPEC-005D](../../specs/SPEC-005D-deploy-new-runtime-path.md) (Ansible + deploy na `/opt/homeserver-services`)

## Cel

Usunąć symlinki wsteczne i artefakty cutover; zostawić jeden kanon: `/opt/homeserver-services`.

## Wymagania

- Compose kontenerów wskazuje `.../homeserver-services/...` (sprawdza `preflight`)
- `APPROVE_DEPLOY=yes` dla kroków zmieniających `/opt`
- Backup `.bak-*` ląduje na Seagate — **nie kasuj** archiwum od razu

## Sekwencja (z Maca)

```bash
cd ~/repos/workspace
chmod +x scripts/migration/g2-runtime-path-cleanup.sh deploy/scripts/cleanup-g2-runtime-path.sh

./deploy/scripts/cleanup-g2-runtime-path.sh preflight

APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh archive-bak --apply
APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh remove-symlinks --apply
APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh remove-stale --apply

./deploy/scripts/cleanup-g2-runtime-path.sh smoke
```

## Po cleanup

- Operacje SSH: `cd /opt/homeserver-services`
- EPIC-005 zamknięty po ADR + aktualizacji runbooków w repo (`SPEC-005E` faza docs)

## Rollback

Przywróć symlinki i dane z `/mnt/seagate/backups/epic-005-g2-runtime-path/cleanup-archive-*` — szczegóły w [SPEC-005E](../../specs/SPEC-005E-runtime-path-cleanup.md).
