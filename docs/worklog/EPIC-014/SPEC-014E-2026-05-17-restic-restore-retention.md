# SPEC-014E — 2026-05-17 — Restic restore drill + retencja HA

## Restore drill

- Snapshot `786f917a` (`t630-config`)
- Plik: `/opt/homeassistant/config/.HA_VERSION`
- Target: `/tmp/restic-restore-test/...`
- `cmp` z produkcją: **OK**

## Retencja lokalna

| Metryka | Przed | Po |
|---------|-------|-----|
| `backup_ha_retention_days` | 5 | **3** |
| `/opt/backups/home-assistant` | 14G (6 plików) | **9.3G** (4 pliki) |
| `/` Avail | 54G | **59G** |

Usunięto 2 archiwa `t630-data` (May 12–13), ~4.7G — po drill, zgodnie z nową retencją.

## EPIC-014 Faza 1

Off-box Restic → MinIO działa; restore potwierdzony. EPIC-006 cutover backupowo odblokowany.

## Runbook

[`docs/runbooks/t630-restic-restore.md`](../../runbooks/t630-restic-restore.md)
