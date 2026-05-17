# SPEC-014D — 2026-05-17 — Restic cron + P1/P2

## Wykonane

- `restic-backup-all.sh`, cron root `30 4 * * *`
- Retencja: 7d / 4w / 6m (`forget --prune`)
- Deploy Ansible `--tags restic-cron`
- Pierwszy run backup-all ~3 min (P0 incremental + P1/P2)

## Snapshots (po backup-all)

| Tag | Rozmiar (przybliż.) |
|-----|-------------------|
| t630-backups | 18 GiB (2 snapshoty — P0 re-run + forget kept) |
| t630-config | 3 GiB |
| t630-openclaw | 97 MiB |
| t630-paperclip | 1.1 GiB |

G2 bucket: ~20 GiB.

## Uwagi

- `t630-forgejo` disabled (brak `/srv/ai-stack/forgejo`)
- Lokalna retencja HA bez zmian (014E)

## Następne

SPEC-014E: restore drill + skrócenie `/opt/backups` lokalnie.
