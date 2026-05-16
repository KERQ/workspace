# SPEC-005B: Migracja ścieżek runtime na G2

Parent: [EPIC-005](epics/EPIC-005-runtime-path-migration.md)
Status: in_progress
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
- [ ] Cutover: symlinki `homeserver-ansible-repo` i `infisical`
- [ ] Smoke PASS
- [ ] Rollback przetestowany lub udokumentowany

## Out of scope

- Zmiana Ansible defaults (SPEC-005D)
- Usunięcie `.bak-*` (SPEC-005E)
- T630
