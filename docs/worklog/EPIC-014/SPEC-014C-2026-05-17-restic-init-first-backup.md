# SPEC-014C — 2026-05-17 — Restic init + pierwszy backup P0

## Cel

`restic` na T630, init repo MinIO G2, pierwszy snapshot `/opt/backups`.

## Wykonane

### Ansible (`homeserver-core` f1447d3+)

- Rola `restic`: pakiet, excludes, `restic-backup-p0.sh`, init, credentials z `RESTIC_PASSWORD`.
- Hasło repo: `inventory/.secrets/restic_repository_password` (kontroler, gitignored).
- Deploy: `ansible-playbook playbooks/t630.yml -l t630 --tags restic,restic-minio`.

### Backup P0

- Ręcznie: `sudo nohup /usr/local/bin/restic-backup-p0.sh` (PID 2089791).
- Czas: ~8 min (źródło ~19G, snapshot ~18 GiB skompresowany).

## Wyniki

| Test | Wynik |
|------|--------|
| `restic snapshots --tag t630-backups` | 1 snapshot `3ae2030b`, 18.043 GiB |
| `restic check` | no errors were found |
| G2 `mc du local/restic-backups` | ~17 GiB |
| `/opt/backups` lokalnie | 19G (bez skracania retencji) |

## Recovery

- **RESTIC_PASSWORD:** `homeserver-core/inventory/.secrets/restic_repository_password` — zachować poza Git (utrata = brak odszyfrowania backupów).

## Następne

- SPEC-014D: cron + P1/P2 + `forget`.
