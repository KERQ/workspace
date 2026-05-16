# SPEC-005B: Migracja ścieżek runtime na G2

Parent: [EPIC-005](epics/EPIC-005-runtime-path-migration.md)
Status: done
Repos: workspace (scripts, runbook)
Host: g2@192.168.1.19
Risk: high

## Cel

Skopiować layout do `/opt/homeserver-services` i przełączyć stare ścieżki na symlinki wsteczne bez utraty danych.

## Artefakty

| Plik | Rola |
|------|------|
| `scripts/migration/g2-runtime-path-migrate.sh` | Logika na G2 |
| `deploy/scripts/migrate-g2-runtime-path.sh` | Wrapper SSH + bramka approve |
| `docs/runbooks/g2-runtime-path-migration.md` | Procedura operacyjna |

## Definition of Done

- [x] Backup na Seagate (`20260516-211159`)
- [x] `/opt/homeserver-services` zsynchronizowany (2026-05-16)
- [x] Cutover: symlinki `homeserver-ansible-repo` i `infisical` (2026-05-16)
- [x] Smoke PASS (Airflow po warmup ~3 min; MinIO/trading OK)
- [x] Rollback udokumentowany w runbooku (nie testowany na produkcji)

## Uwagi operacyjne

- `cp -a src/*` nie kopiuje plików ukrytych — naprawiono w skrypcie + ręczny restore `.env` Infisical z `.bak-*`
- Backupy cutover: `/opt/homeserver-ansible-repo.bak-20260516-211434`, `/opt/homeserver-ansible-infisical.bak-20260516-211434`

## Out of scope

- Zmiana Ansible defaults (SPEC-005D)
- Usunięcie `.bak-*` (SPEC-005E)
- T630
