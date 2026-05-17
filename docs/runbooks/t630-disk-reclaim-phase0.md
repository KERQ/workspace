# Runbook: T630 — zwolnienie miejsca (Faza 0, SPEC-014A)

Jednorazowe i konfiguracyjne kroki **przed** Restic/Forgejo. Wymaga approval na operacje destrukcyjne.

## Baseline

```bash
ssh t630@192.168.1.20 'df -h /; echo "---"; du -sh /opt/backups/* 2>/dev/null | sort -hr; echo "---"; docker system df 2>/dev/null'
```

Zapisz wynik w SPEC-014A (sekcja test plan).

## 1. Deploy Ansible (backup retencja)

Po merge zmian w `homeserver-core`:

```bash
cd ~/repos/workspace
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-t630-full.sh --tags backup
```

Weryfikacja skryptu:

```bash
ssh t630@192.168.1.20 'grep -E "RETENTION|t630-data" /usr/local/bin/backup-ha.sh; crontab -l -u t630 | grep -i backup'
```

## 2. Jednorazowe usunięcie starych archiwów HA

**Tylko** pliki w `/opt/backups/home-assistant` starsze niż 5 dni (zgodnie z nową retencją).

Dry-run:

```bash
ssh t630@192.168.1.20 'find /opt/backups/home-assistant -type f -mtime +5 -print | wc -l; find /opt/backups/home-assistant -type f -mtime +5 -print | head -20'
```

Szacunek rozmiaru do usunięcia:

```bash
ssh t630@192.168.1.20 'find /opt/backups/home-assistant -type f -mtime +5 -printf "%s\n" | awk "{s+=\$1} END {print s/1024/1024/1024 \" GB\"}"'
```

Wykonanie (**po explicit approval**):

```bash
ssh t630@192.168.1.20 'find /opt/backups/home-assistant -type f -mtime +5 -delete'
```

## 3. Opcjonalnie: Docker — nieużywane obrazy (~16G reclaimable)

Dry-run:

```bash
ssh t630@192.168.1.20 'docker image prune -a --filter "until=168h"'
```

Wykonanie (**po explicit approval**):

```bash
ssh t630@192.168.1.20 'docker image prune -a -f --filter "until=168h"'
```

## 4. Opcjonalnie: legacy OpenClaw (~4,4G)

Sprawdź, że aktywny katalog to `~/.openclaw`, nie legacy:

```bash
ssh t630@192.168.1.20 'du -sh /home/t630/.openclaw /home/t630/.openclaw.legacy-* 2>/dev/null; systemctl --user is-active openclaw-studio 2>/dev/null || true'
```

Usunięcie (**po explicit approval**):

```bash
ssh t630@192.168.1.20 'rm -rf /home/t630/.openclaw.legacy-20260504-151711'
```

## Post-check

```bash
ssh t630@192.168.1.20 'df -h /'
```

Cel EPIC-014: **Avail ≥20G** na `/`.

## Rollback

- Przywróć `backup_ha_retention_days: 14` i `backup_ha_include_t630_data: true` w Ansible — redeploy.
- Usuniętych tarów nie przywrócisz bez kopii zewnętrznej — przed krokiem 2 rozważ skopiowanie najnowszego `t630-data-*.tar.gz` poza T630.
