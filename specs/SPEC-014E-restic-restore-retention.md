# SPEC-014E: T630 — restore drill i skrócenie lokalnej retencji HA

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: draft *(szkic)*
Repo: homeserver-core + workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-014D](SPEC-014D-restic-cron-paths.md)

## Cel (szkic)

- Restore drill: odtworzenie pojedynczego pliku z snapshotu Restic (np. z `/opt/backups/home-assistant`).
- Po sukcesie: ewentualne dalsze skrócenie lokalnej retencji HA (jeśli jeszcze za dużo miejsca zajmuje `/opt/backups`).
- Runbook: `docs/runbooks/t630-restic-restore.md`.

Szczegóły — po zamknięciu SPEC-014D.
