# SPEC-006E: T630 — Forgejo backup + contracts

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: done
Repo: homeserver-core, workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-006D](SPEC-006D-forgejo-remotes-pr-smoke.md)

## Cel

Domknąć MVP Forgejo od strony operacyjnej: backup DB + danych Forgejo przez istniejący Restic → MinIO G2, restore drill oraz aktualizacja kontraktu portów.

## Wykonane

1. Lokalny dump DB:
   - skrypt `/usr/local/bin/backup-forgejo.sh`
   - cron `20 3 * * *` jako użytkownik `t630`
   - output `/opt/backups/forgejo/forgejo-*.sql.gz`
   - retencja lokalna 7 dni
2. Restic:
   - tag `t630-forgejo` aktywny
   - ścieżki: `/opt/backups/forgejo`, `/srv/ai-stack/forgejo`
   - nightly przez `/usr/local/bin/restic-backup-all.sh` o 04:30
3. Restore drill:
   - snapshot `3ee8a230`
   - restore dumpu do `/tmp/restic-forgejo-restore-test`
   - `gzip -t` OK
4. Contract:
   - `contracts/services/ports.yml` → `forgejo_web.status: active`
   - URL: `https://t630.colobus-micro.ts.net/git/`

## Smoke

```bash
ssh t630@192.168.1.20 'sudo -u t630 /usr/local/bin/backup-forgejo.sh'

ssh t630@192.168.1.20 'sudo bash -c "
  set -a; . /etc/restic/credentials.env; set +a
  export AWS_S3_FORCE_PATH_STYLE=true
  restic snapshots --tag t630-forgejo
"'
```

Wynik: snapshot `3ee8a230`, restore drill OK.

## Uwagi

- Backup live katalogu PostgreSQL sam w sobie nie jest traktowany jako kanoniczny restore DB. Kanoniczny restore DB w MVP zaczyna się od dumpu `forgejo-*.sql.gz`.
- `/srv/ai-stack/forgejo` jest nadal backupowany, bo zawiera dane aplikacji i repozytoria Git.
- Sekrety Restic pozostają poza Git.

## Następne

- EPIC-006 można zamknąć jako MVP done.
