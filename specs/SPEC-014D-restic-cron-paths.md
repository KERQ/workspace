# SPEC-014D: T630 — Restic cron, retencja i zestawy P1/P2

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: done
Repo: homeserver-core (+ workspace: runbook)
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-014C](SPEC-014C-restic-init-first-backup.md)
Blokuje: [SPEC-014E](SPEC-014E-restic-restore-retention.md) — restore drill + skrócenie lokalnej retencji

## Cel

Zautomatyzować codzienne backupy Restic na T630 do MinIO G2: **wszystkie zestawy P0–P2** (jedno repo, tagi), **cron**, polityka **`forget --prune`**, logi — bez skracania lokalnej retencji `/opt/backups` (to SPEC-014E).

## Kontekst

- [SPEC-014C](SPEC-014C-restic-init-first-backup.md) — init + pierwszy snapshot P0 (~18 GiB).
- Lokalne cron `roles/backup` kończą ~03:45; Restic start **04:30**.
- Forgejo (`/srv/ai-stack/forgejo`) — wyłączone do EPIC-006.

## Decyzje

| Temat | Wartość |
|-------|---------|
| Harmonogram | `30 4 * * *` (root) |
| Skrypt | `/usr/local/bin/restic-backup-all.sh` |
| Retencja | `--keep-daily 7 --keep-weekly 4 --keep-monthly 6` |
| Lock | `/var/run/restic-backup.lock` (flock) |
| Logi | `/var/log/restic/backup-all-*.log` |

## Zestawy ścieżek

| Tag | Ścieżki | Status |
|-----|---------|--------|
| `t630-backups` | `/opt/backups` | P0 |
| `t630-config` | `/opt/life-platform-t630`, `/opt/homeassistant`, `/opt/t630-data` | P1 |
| `t630-openclaw` | `/home/t630/.openclaw`, `/opt/openclaw` | P1 |
| `t630-paperclip` | `/home/t630/.paperclip`, `/opt/paperclip-workspaces` | P2 |
| `t630-forgejo` | `/srv/ai-stack/forgejo` | disabled |

Brakujące ścieżki są pomijane (bez błędu).

## Zakres

### In scope

- Szablon `restic-backup-all.sh.j2`, cron root, zmienne `restic_backup_sets`.
- Deploy Ansible tag `restic-cron`.
- Pierwszy run `backup-all` po deploy (seed P1/P2).
- Runbook operacyjny.

### Out of scope

- Restore drill, skrócenie `backup_ha_retention_days` → **014E**.
- Backup G2 hosta.
- Włączenie `t630-forgejo`.

## Pliki

| Repo | Pliki |
|------|-------|
| `homeserver-core` | `roles/restic/tasks/cron.yml`, `templates/restic-backup-all.sh.j2`, `defaults/main.yml` |
| `workspace` | ten SPEC, `docs/runbooks/t630-restic-cron.md`, worklog |

## Do zrobienia

- [x] Implementacja roli + syntax-check
- [x] Deploy `--tags restic-cron,restic-minio,restic`
- [x] Pierwszy `backup-all` (~3 min)
- [x] Cron, 5 snapshots (4 tagi aktywne), forget OK
- [x] Worklog

## Definition of Done

- [x] Cron `30 4 * * *` (root)
- [x] Snapshots: t630-backups, t630-config, t630-openclaw, t630-paperclip
- [x] `forget --prune` w logu
- [x] Lokalna retencja HA bez zmian

## Test plan

```bash
# Po deploy
ssh t630@192.168.1.20 'sudo crontab -l | grep -i restic'
ssh t630@192.168.1.20 'sudo /usr/local/bin/restic-backup-all.sh'  # lub nohup

# Po backup-all
ssh t630@192.168.1.20 'sudo bash -c "set -a; . /etc/restic/credentials.env; set +a; export AWS_S3_FORCE_PATH_STYLE=true; restic snapshots"'
ssh t630@192.168.1.20 'sudo ls -lt /var/log/restic/ | head -5'
```

## Rollback

- Usunąć cron: `restic_cron_enabled: false` + redeploy.
- Repo Restic na MinIO zostaje (dane z 014C).

## Approval gates

| Gate | Wymagane |
|------|----------|
| Deploy T630 `--tags restic-cron` | `APPROVE_DEPLOY=yes` |
| Pierwszy backup-all | implicit (obciążenie LAN/dysk) |

## Work log

- [2026-05-17](../docs/worklog/EPIC-014/SPEC-014D-2026-05-17-restic-cron-paths.md)

## Prompt plan

1. Deploy roli.
2. Uruchom `backup-all` (nohup jeśli długo).
3. Sprawdź snapshots i cron.
4. Nie zmieniaj lokalnej retencji HA.
