# SPEC-006E — 2026-05-17 — Forgejo backup + contracts

## Wykonane

- Dodano `backup-forgejo.sh` w `homeserver-core`:
  - `pg_dump -U forgejo -d forgejo` z kontenera `forgejo-db`
  - gzip do `/opt/backups/forgejo/`
  - lokalna retencja 7 dni
- Dodano cron T630:
  - `20 3 * * * /usr/local/bin/backup-forgejo.sh`
- Włączono Restic tag `t630-forgejo`:
  - `/opt/backups/forgejo`
  - `/srv/ai-stack/forgejo`
- Zaktualizowano `forgejo_web` w `contracts/services/ports.yml` na `active`.

## Smoke

| Test | Wynik |
|------|--------|
| `backup-forgejo.sh` | OK |
| Dump | `/opt/backups/forgejo/forgejo-2026-05-17_115109.sql.gz` |
| Restic snapshot | `3ee8a230` (`t630-forgejo`) |
| Snapshot paths | `/opt/backups/forgejo`, `/srv/ai-stack/forgejo` |
| Restore drill dumpu | OK (`gzip -t`) |
| Cron Restic | `30 4 * * * /usr/local/bin/restic-backup-all.sh` |
| Cron Forgejo dump | `20 3 * * * /usr/local/bin/backup-forgejo.sh` |

## Uwagi

- Pierwszy deploy `--tags backup,restic-cron` ujawnił, że pre-taski sekretów Restic nie miały tagu `restic-cron`; dodano ten tag do ładowania sekretów w `playbooks/t630.yml`.
- Drugi snapshot `t630-forgejo` dodano po dopisaniu `/opt/backups/forgejo`, żeby tag był samowystarczalny dla restore DB + danych.

## Następne

- EPIC-006 można zamknąć jako MVP done.
