# Runbook: T630 — Restic restore (SPEC-014E)

Wymaga działającego repo ([SPEC-014C](t630-restic-first-backup.md)) i haseł w `/etc/restic/credentials.env` + kopia `restic_repository_password` na kontrolerze.

## Przygotowanie

```bash
ssh t630@192.168.1.20 'sudo bash -c "
  set -a; . /etc/restic/credentials.env; set +a
  export AWS_S3_FORCE_PATH_STYLE=true
  restic snapshots
"'
```

## Restore pojedynczego pliku (drill)

```bash
ssh t630@192.168.1.20 'sudo bash -c "
set -euo pipefail
set -a; . /etc/restic/credentials.env; set +a
export AWS_S3_FORCE_PATH_STYLE=true
TARGET=/tmp/restic-restore-test
rm -rf \"\$TARGET\" && mkdir -p \"\$TARGET\"
restic restore latest --tag t630-config --target \"\$TARGET\" \
  --include /opt/homeassistant/config/.HA_VERSION
cmp \"\$TARGET/opt/homeassistant/config/.HA_VERSION\" /opt/homeassistant/config/.HA_VERSION
echo RESTORE_DRILL_OK
"'
```

## Restore katalogu (ostrożnie)

```bash
# Przykład: cały /opt/backups z ostatniego snapshotu P0
TARGET=/tmp/restic-restore-full
sudo rm -rf "$TARGET"
sudo bash -c 'set -a; . /etc/restic/credentials.env; set +a; export AWS_S3_FORCE_PATH_STYLE=true; \
  restic restore latest --tag t630-backups --target '"$TARGET"' --path /opt/backups'
```

**Nie** nadpisuj produkcyjnych ścieżek bez zatrzymania usług i kopii lokalnej.

## Restore Forgejo dump drill

```bash
ssh t630@192.168.1.20 'sudo bash -c "
set -euo pipefail
set -a; . /etc/restic/credentials.env; set +a
export AWS_S3_FORCE_PATH_STYLE=true
TARGET=/tmp/restic-forgejo-restore-test
rm -rf \"\$TARGET\" && mkdir -p \"\$TARGET\"
restic restore latest --tag t630-forgejo --target \"\$TARGET\" \
  --include /opt/backups/forgejo/*.sql.gz
find \"\$TARGET/opt/backups/forgejo\" -type f -name \"*.sql.gz\" -exec gzip -t {} \;
echo FORGEJO_RESTORE_DRILL_OK
"'
```

Do restore produkcyjnego DB użyj najpierw dumpu `forgejo-*.sql.gz`; live katalog PostgreSQL w `/srv/ai-stack/forgejo/postgres` jest backupowany jako dodatkowy stan wolumenu, nie jako preferowany punkt odtwarzania DB.

## Po skróceniu lokalnej retencji HA

Lokalne pliki starsze niż `backup_ha_retention_days` są usuwane przez `backup-ha.sh`. Odtworzenie archiwów: restore z tagu `t630-backups` jak wyżej.

## Hasło repo

Utrata `homeserver-core/inventory/.secrets/restic_repository_password` = brak odszyfrowania backupów.
