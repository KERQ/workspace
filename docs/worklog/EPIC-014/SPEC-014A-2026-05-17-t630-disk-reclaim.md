# SPEC-014A — 2026-05-17 — T630 disk reclaim phase0

## Cel sesji

Zwolnić miejsce na root filesystem T630 przed dalszą pracą nad Restic/MinIO i Forgejo, bez usuwania danych produkcyjnych poza lokalnymi archiwami backup/cache.

## Kontekst

- Parent: [EPIC-014](../../../specs/epics/EPIC-014-restic-minio-offbox-backup.md)
- SPEC: [SPEC-014A](../../../specs/SPEC-014A-t630-disk-reclaim-phase0.md)
- Runbook: [t630-disk-reclaim-phase0](../../runbooks/t630-disk-reclaim-phase0.md)

## Wykonane

- W `homeserver-core` skrócono retencję backupów HA na T630 do 5 dni.
- Dodano `backup_ha_include_t630_data: false`, aby zatrzymać codzienny tar `/opt/t630-data` (~2.4 GB/dzień).
- Wdrożono rolę backup na T630 przez Ansible z `APPROVE_DEPLOY=yes`.
- Usunięto stare archiwa HA starsze niż 5 dni.
- Uruchomiono `docker image prune` dla nieużywanych obrazów.
- Usunięto legacy katalog OpenClaw po potwierdzeniu aktywnego `~/.openclaw`.
- Udokumentowano runbook Fazy 0.

## Testy / komendy

| Krok | Wynik |
|------|-------|
| Baseline `df -h /` | 95G used, 10G avail, 91% |
| Baseline `/opt/backups/home-assistant` | ~40G |
| `ansible-playbook playbooks/t630.yml -l t630 --tags backup --syntax-check` | OK |
| Deploy `ansible-playbook playbooks/t630.yml -l t630 --tags backup` | OK, `changed=1` dla `backup-ha.sh` |
| Weryfikacja skryptu | `RETENTION_DAYS=5`, brak bloku `t630-data` |
| Dry-run cleanup | 60 plików, ~25.2G do usunięcia |
| `find /opt/backups/home-assistant -type f -mtime +5 -delete` | OK, `/` 36G avail |
| `docker image prune -a -f --filter "until=168h"` | ~4.7G reclaim |
| `sudo rm -rf /home/t630/.openclaw.legacy-20260504-151711` | OK |
| Final `df -h /` | 51G used, 55G avail, 49% |

## Wyniki

- Cel EPIC-014 Faza 0 spełniony: T630 ma **55G wolne** na `/` (wymagane ≥20G).
- `/opt/backups/home-assistant` spadło z ~40G do ~14G.
- Codzienny backup nie będzie już tworzył `t630-data-*.tar.gz`.

## Problemy / ryzyka

- Kontener `caddy` był w pętli restart z błędem `:80 address already in use`.
- To nie wygląda na skutek SPEC-014A, ale blokuje przyszłe prace Forgejo/Caddy i wymaga osobnego SPEC/fix przed EPIC-006.
- `docker image prune` odzyskał mniej niż wcześniejszy raport `docker system df` sugerował jako reclaimable (~4.7G vs ~16G), prawdopodobnie przez aktywne tagi/warstwy.

## Commity

- `workspace`: `b434b7a` — `docs: SPEC-014A zwolnienie miejsca T630 + runbook phase0`
- `homeserver-core`: `9476de1` — `feat(backup): SPEC-014A krótsza retencja HA na T630, bez dziennego t630-data`
- `workspace`: `56212c7` — `docs: SPEC-014A done — T630 55G wolne po reclaim Fazy 0`

## Follow-up

- [ ] SPEC-014B: MinIO bucket + dostęp T630 -> G2.
- [ ] Osobny SPEC/fix: konflikt Caddy na T630 (`:80 address already in use`).
- [ ] Po Restic restore drill skrócić lokalne retencje docelowo i zdefiniować politykę dla `t630-data`.
