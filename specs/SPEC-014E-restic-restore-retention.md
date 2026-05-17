# SPEC-014E: T630 — restore drill i skrócenie lokalnej retencji HA

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: done
Repo: homeserver-core + workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-014D](SPEC-014D-restic-cron-paths.md)

## Cel

Potwierdzić odtwarzalność z Restic (restore drill) i po sukcesie skrócić lokalną retencję HA — mając kanoniczny off-box backup na MinIO G2.

## Zakres

### In scope

- Restore drill: pojedynczy plik z snapshotu `t630-config`.
- `backup_ha_retention_days`: **5 → 3** w Ansible.
- Jednorazowe usunięcie archiwów HA starszych niż 3 dni w `/opt/backups/home-assistant`.
- Runbook: [`docs/runbooks/t630-restic-restore.md`](../docs/runbooks/t630-restic-restore.md).
- Worklog; zamknięcie Fazy 1 EPIC-014 (poza monitoringiem opcjonalnym).

### Out of scope

- Zmiana retencji Restic (`forget`) — już w 014D.
- Usuwanie `/opt/backups` bez Restic.

## Wykonane (2026-05-17)

### Restore drill

- Snapshot: `786f917a` (`t630-config`).
- Plik: `/opt/homeassistant/config/.HA_VERSION` → `/tmp/restic-restore-test/...`
- `cmp` z oryginałem: **OK** (treść `2026.3.1`).

### Retencja lokalna

- Ansible: `backup_ha_retention_days: 3`.
- Deploy roli `backup` na T630.
- Jednorazowe: `find /opt/backups/home-assistant -type f -mtime +3 -delete`.

## Definition of Done

- [x] Restore drill udokumentowany i wykonany
- [x] `backup_ha_retention_days: 3` wdrożone
- [x] Post-check `du` / `df` w worklog
- [x] Runbook restore opublikowany
- [x] EPIC-014 Faza 1 gotowa do zamknięcia (off-box + drill)

## Test plan (wykonany)

```bash
# restore — patrz runbook
# po cleanup:
ssh t630@192.168.1.20 'du -sh /opt/backups/home-assistant; df -h /'
```

## Rollback

| Zmiana | Cofnięcie |
|--------|-----------|
| retencja 3 dni | `backup_ha_retention_days: 5` + redeploy backup |
| usunięte archiwa lokalne | `restic restore` z tagu `t630-backups` |

## Work log

- [2026-05-17](../docs/worklog/EPIC-014/SPEC-014E-2026-05-17-restic-restore-retention.md)

## Prompt plan

1. Restore drill przed jakimkolwiek `find -delete`.
2. Deploy Ansible backup.
3. Cleanup starych tarów zgodnie z nową retencją.
4. Nie dotykaj retencji Restic w tym SPEC.
