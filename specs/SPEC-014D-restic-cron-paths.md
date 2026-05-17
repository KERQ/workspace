# SPEC-014D: T630 — Restic cron, retencja i zestawy P1/P2

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: draft *(szkic — implementacja po SPEC-014C)*
Repo: homeserver-core
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-014C](SPEC-014C-restic-init-first-backup.md)

## Cel (szkic)

Automatyzacja backupów Restic na T630: cron, polityka `forget --prune`, zestawy ścieżek P1/P2 z EPIC-014, logowanie błędów.

## Zakres (planowany)

- systemd timer lub cron dla `restic-backup-all.sh`
- Retencja: np. `--keep-daily 7 --keep-weekly 4 --keep-monthly 6`
- Ścieżki: `t630-config`, `t630-openclaw`, `t630-paperclip` (P2 opcjonalnie)
- Tagi per zestaw; jedno repo S3

Szczegóły — po zamknięciu SPEC-014C.
