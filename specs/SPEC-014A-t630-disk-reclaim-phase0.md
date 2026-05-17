# SPEC-014A: T630 — zwolnienie miejsca (Faza 0 EPIC-014)

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: done
Repo: homeserver-core (+ workspace: runbook)
Owner: karolkurek
Risk: medium
Type: infra

## Cel

Zwolnić **≥20 GB** na `/` T630 przed Restic/Forgejo przez redukcję lokalnych backupów HA i jednorazowe sprzątanie — **bez** usuwania danych produkcyjnych poza archiwami backup/cache.

## Kontekst

Audyt 2026-05-17: `/` 91% (95G/110G), `/opt/backups` ~44G (HA ~40G, `t630-data-*.tar.gz` ~2,4G/dzień × retencja 14d).

## Zakres

### In scope

- Ansible: `backup_ha_retention_days` **14 → 5** na T630 (`group_vars/t630_servers.yml`).
- Ansible: `backup_ha_include_t630_data: false` — wyłączyć dzienny tar `/opt/t630-data` (największy plik); config HA nadal codziennie.
- Runbook: jednorazowe `find -mtime` w `/opt/backups/home-assistant`, opcjonalnie `docker image prune`, legacy OpenClaw — **po explicit approval**.
- Baseline i post-check `df` / `du` udokumentowane w tym SPEC.

### Out of scope

- Restic/MinIO (SPEC-014B–E).
- Deploy playbook na T630 bez `APPROVE_DEPLOY=yes`.
- Automatyczne `docker prune` / `rm` legacy bez zgody.

## Pliki / obszary

### Read

- `homeserver-core/roles/backup/templates/backup-ha.sh.j2`
- `homeserver-core/roles/backup/defaults/main.yml`
- [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)

### Write

- `homeserver-core/inventory/group_vars/t630_servers.yml`
- `homeserver-core/roles/backup/defaults/main.yml` (nowa zmienna domyślna)
- `homeserver-core/roles/backup/templates/backup-ha.sh.j2`
- `workspace/docs/runbooks/t630-disk-reclaim-phase0.md`

### Forbidden

- Sekrety w Git.
- Skracanie retencji przed ręcznym backupem „na wszelki wypadek” — zalecany tarball jednego najnowszego `t630-data` na G2/USB jeśli Restic jeszcze nie działa (opcjonalnie, ręcznie).

## Do zrobienia

- [x] SPEC-014A utworzony
- [x] Zmiany Ansible (retencja + `backup_ha_include_t630_data`) — `homeserver-core` `9476de1`
- [x] Runbook phase0 w workspace
- [x] `ansible-playbook --syntax-check` (T630 playbook)
- [x] Deploy roli backup na T630 (`APPROVE_DEPLOY=yes`, 2026-05-17)
- [x] Jednorazowe sprzątanie starych archiwów HA (60 plików, ~25G)
- [x] `docker image prune` (~4,7G) + legacy OpenClaw (`sudo rm`, ~4,4G)
- [x] Post-check: `df /` **55G Avail** (cel ≥20G)

## Definition of Ready

- [x] Cel i zakres jasne
- [x] Test plan zdefiniowany
- [x] Approval na deploy T630

## Definition of Done

- [x] Ansible wdrożony na T630 (skrypt backup-ha z nowymi zmiennymi)
- [x] Jednorazowe usunięcie archiwów HA starszych niż 5 dni
- [x] `df -h /` pokazuje ≥20G Available (**55G**)
- [x] Wyniki test plan w sekcji poniżej
- [x] Runbook opublikowany

## Test plan

### Przed zmianami (baseline)

```bash
ssh t630@192.168.1.20 'df -h /; du -sh /opt/backups/* 2>/dev/null | sort -hr'
```

### Po zmianie Ansible (bez deploy — lokalnie)

```bash
cd ~/repos/homeserver-core
ansible-playbook playbooks/t630.yml -l t630 --tags backup --syntax-check
```

### Po deploy (wymaga approval)

```bash
cd ~/repos/workspace
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-t630-full.sh --tags backup
# lub z homeserver-core:
# APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags backup
```

### Jednorazowe sprzątanie (po deploy lub równolegle — approval)

Zobacz [`docs/runbooks/t630-disk-reclaim-phase0.md`](../docs/runbooks/t630-disk-reclaim-phase0.md).

### Po sprzątaniu (oczekiwany wynik)

```bash
ssh t630@192.168.1.20 'df -h /; ls -1 /opt/backups/home-assistant | wc -l; du -sh /opt/backups/home-assistant'
```

**Sukces:** Avail ≥20G; liczba plików HA spada (docelowo ≤~15 przy 5 dniach × ~3 pliki/dzień bez t630-data).

## Test plan (wykonany)

**Baseline:** 95G used, 10G avail (91%), `/opt/backups/home-assistant` ~40G.

| Krok | Wynik |
|------|--------|
| Deploy `--tags backup` | `backup-ha.sh` changed; `RETENTION_DAYS=5`; brak bloku `t630-data` |
| `find -mtime +5 -delete` | 60 plików, ~25G zwolnione → **36G avail** (67%) |
| `docker image prune` | ~4,7G → **50G avail** (53%) |
| `sudo rm` legacy OpenClaw | ~4,4G → **55G avail** (49%) |
| `/opt/backups/home-assistant` | 14G (6 plików pozostałych) |

**Uwaga:** kontener `caddy` w pętli restart (`:80 address already in use`) — istniejący problem infra, nie wynik backupu; do osobnego SPEC/fix.

## Work log

- [2026-05-17 — T630 disk reclaim phase0](../docs/worklog/EPIC-014/SPEC-014A-2026-05-17-t630-disk-reclaim.md)

## Rollback

| Zmiana | Cofnięcie |
|--------|-----------|
| `backup_ha_retention_days: 5` | Przywrócić `14` w `t630_servers.yml` + redeploy backup |
| `backup_ha_include_t630_data: false` | Ustawić `true` + redeploy |
| Usunięte archiwa | Brak auto-rollback — odtworzenie z pozostałych tarów lub przyszły Restic |

## Prompt plan

1. Przeczytaj ten SPEC i runbook phase0.
2. Wdróż zmiany Ansible; syntax-check.
3. **Nie** uruchamiaj `find -delete` ani `docker prune` bez explicit approval użytkownika.
4. Po każdym kroku: `df -h /` i wpisz wynik do „Test plan (wykonany)”.

## Na później

- Przeniesienie backupów HA wyłącznie do Restic (SPEC-014C–E).
- Osobny tygodniowy job dla `t630-data` jeśli okaże się potrzebny.
