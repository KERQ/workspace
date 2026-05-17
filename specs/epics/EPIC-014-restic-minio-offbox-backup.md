# EPIC-014: Restic → MinIO — backup off-box i zwolnienie miejsca na T630

Status: draft
Owner: karolkurek
Risk: high
Repos: homeserver-core, workspace (docs/contracts/runbooks)
Blokuje: [EPIC-006](EPIC-006-forgejo-mvp.md) (cutover Forgejo dopiero po stabilnym backupie off-box i min. ~20 GB wolnego na `/`)

## Cel

1. **Zabezpieczyć miejsce na dysku T630** przed dalszą infrastrukturą (Forgejo, `/srv/ai-stack`).
2. Wdrożyć **kanoniczny backup off-box**: **Restic** z T630 → **MinIO na G2** (`/mnt/seagate`, ~21 TB wolne).
3. Po pierwszym udanym backupie off-box — **zredukować lokalną retencję** w `/opt/backups` (szczególnie Home Assistant ~40G).

## Kontekst

### Audyt dysku T630 (2026-05-17)

| Ścieżka | Rozmiar | Uwagi |
|---------|---------|--------|
| `/` łącznie | 95G / 110G (**91%**) | ~10G wolne |
| `/opt/backups` | **~44G** | Główny problem |
| → `home-assistant/` | **~40G** | 66 plików; `t630-data-*.tar.gz` ~2,4G/dzień |
| → `paperclip/` | ~3,9G | |
| → `openclaw/` | ~295M | |
| `/var/lib/containerd` | ~22G | Obrazy kontenerów |
| Docker images (raport) | ~23G | **~16G reclaimable** (nieużywane obrazy) |
| `/home/t630/.openclaw.legacy-*` | **~4,4G** | Kandydat do usunięcia po weryfikacji |

### Cel backupu (G2)

| Host | Dysk | Wolne |
|------|------|-------|
| G2 `/mnt/seagate` | 22T | ~21T (6% użyte) |
| MinIO na G2 | `minio-minio-1` `127.0.0.1:19000` (+ plane instancje) | Docelowy backend Restic — **osobny bucket** `restic-backups` (do utworzenia w SPEC-014B) |

Źródła:

- [`BACKLOG.md`](../../BACKLOG.md) — EPIC-014 **Next**, must-have przed cutover Forgejo.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md) — §16 Backupy (Restic/MinIO).
- Istniejąca rola `homeserver-core/roles/backup` — lokalne cron + `/opt/backups` (zostaje jako warstwa awaryjna krótkiej retencji).

## Decyzje wstępne

| Temat | Propozycja | Uwagi |
|-------|------------|--------|
| Backend | MinIO na **G2** | Duży dysk Seagate; nie zapychać T630 |
| Dostęp T630 → MinIO | Tailscale / sieć wewnętrzna | Endpoint i credentials poza Git (Ansible Vault / host_vars lokalne) |
| Narzędzie | **restic** | Szyfrowanie repo, retencja policy, restore drill |
| Lokalne `/opt/backups` | Zostaje; **krótsza retencja** po Restic | Np. HA: 14 → 3–5 dni |
| Forgejo (przyszłość) | Ścieżki w Restic od razu w planie | `/srv/ai-stack/forgejo/` gdy powstanie (EPIC-006) |
| investment-research | Osobna polityka / bucket | Hard privacy — poza domyślnym bucketem infra |

## Repo impact matrix

| Repo | Impact | Uwagi |
|------|--------|-------|
| `homeserver-core` | write | Restic install, cron, zmiana retencji `backup_*`, ewent. rola `restic` |
| `workspace` | write | EPIC, SPECs, runbook restore, kontrakt backup paths |
| `homeserver-services` | read | Brak zmian w MVP 014 |
| `life-platform` | read | Ścieżki `t630-config` w backup HA |

## In scope

### Faza 0 — natychmiastowe zwolnienie miejsca (bez Restic)

- Udokumentowany audyt (ten EPIC + runbook).
- Redukcja retencji lokalnych backupów HA (`backup_ha_retention_days`).
- Opcjonalnie: wyłączenie lub rzadszy harmonogram `t630-data-*.tar.gz` (największy plik ~2,4G/dzień).
- `docker image prune` na T630 (po approval, tylko nieużywane obrazy).
- Usunięcie `.openclaw.legacy-*` po potwierdzeniu użytkownika.
- Cel: **≥20 GB wolne** na `/` przed EPIC-006 cutover.

### Faza 1 — Restic → MinIO

- Bucket MinIO na G2 (`restic-backups` lub równoważny).
- Instalacja `restic` na T630, inicjalizacja repozytorium.
- Backup zestawów ścieżek (patrz tabela poniżej).
- Harmonogram cron + polityka retencji Restic (np. daily 7, weekly 4, monthly 6).
- **Restore drill** na jednym małym zbiorze (np. pojedynczy plik z HA config).
- Monitoring: alert przy nieudanym `restic backup` (minimum: log + exit code w cron mail).

### Ścieżki do Restic (MVP)

| Zestaw | Ścieżki (T630) | Priorytet |
|--------|----------------|-----------|
| `t630-backups` | `/opt/backups` | P0 — po Faza 0 można skrócić lokalnie |
| `t630-config` | `/opt/life-platform-t630`, `/opt/homeassistant`, `/opt/t630-data` (bez dużych modeli jeśli wykluczone) | P1 |
| `t630-openclaw` | `/home/t630/.openclaw`, `/opt/openclaw` | P1 |
| `t630-paperclip` | `/home/t630/.paperclip`, `/opt/paperclip-workspaces` | P2 |
| `t630-forgejo` | `/srv/ai-stack/forgejo` | P2 — gdy EPIC-006 utworzy katalog |

Wykluczenia jawne: `node_modules`, `.npm`, cache przeglądarek, `*.legacy-*` (po migracji — nie backupować na stałe).

## Out of scope

- Pełna migracja wszystkich backupów G2 (OpenClaw memory na Seagate ma własny skrypt) — osobny SPEC jeśli potrzeba unifikacji.
- Backup `investment-research` do wspólnego bucketu — domyślnie **nie**.
- Automatyczny `restic` z G2 na zewnętrzny cloud — później.
- Zastąpienie GitHub mirror (EPIC-011).

## Guardrails

```text
- no rm -rf /opt/backups bez wcześniejszego udanego restic snapshot
- no secrets w Git (RESTIC_PASSWORD, MinIO keys)
- no prune docker bez explicit approval
- restore drill przed skróceniem lokalnej retencji HA
- APPROVE_DEPLOY=yes dla zmian Ansible na T630/G2
```

## Kolejność wdrożenia (child SPECs)

```text
014A (zwolnienie miejsca — retencja, prune, legacy)     ← najpierw
  → 014B (MinIO bucket + dostęp z T630)
  → 014C (restic init + pierwszy backup ręczny)
  → 014D (cron + retencja Restic + ścieżki)
  → 014E (restore drill + skrócenie lokalnej retencji + runbook)
```

## Global Definition of Done

- [ ] Na T630: `df /` pokazuje **≥20G Avail** (lub uzasadniony niższy próg zapisany w ADR)
- [ ] Restic repo na MinIO G2 istnieje; `restic snapshots` pokazuje ≥1 snapshot per zestaw P0/P1
- [ ] Restore drill udokumentowany i wykonany (wynik w SPEC-014E)
- [ ] Lokalna retencja HA skrócona; rozmiar `/opt/backups/home-assistant` maleje w czasie
- [ ] Runbook: `docs/runbooks/t630-restic-minio-backup.md`
- [ ] EPIC-006 może przejść do cutover (backup off-box gotowy)

## Global test plan

### Faza 0 (przed zmianami produkcyjnymi)

```bash
# baseline
ssh t630@192.168.1.20 'df -h / && du -sh /opt/backups/*'
```

Po 014A:

```bash
ssh t630@192.168.1.20 'df -h / && du -sh /opt/backups/* && docker system df'
```

### Faza 1 (Restic)

```bash
# z T630 (po konfiguracji — bez wartości sekretów w logach)
restic -r s3:https://<minio-endpoint>/<bucket> snapshots
restic check
# restore drill — pojedynczy plik do /tmp/restic-restore-test
```

## Work log

- [SPEC-014A — 2026-05-17 — T630 disk reclaim phase0](../../docs/worklog/EPIC-014/SPEC-014A-2026-05-17-t630-disk-reclaim.md)

## Rollback

| Poziom | Działanie |
|--------|-----------|
| 014A retencja | Przywrócić poprzednie `backup_ha_retention_days` w Ansible |
| Restic | Lokalne `/opt/backups` nadal działają do czasu skrócenia retencji |
| Po skróceniu retencji | Odtworzenie z ostatniego snapshot Restic (runbook 014E) |

## Approval gates

| Gate | Wymagane approval |
|------|-------------------|
| Start EPIC | karolkurek |
| 014A docker prune + usunięcie legacy | **explicit** per operacja |
| 014B–E deploy Ansible / pierwszy backup | `APPROVE_DEPLOY=yes` |
| Skrócenie retencji HA | po udanym restore drill |

## Ryzyka

| Ryzyko | Mitigacja |
|--------|-----------|
| Usunięcie backupów przed Restic | Kolejność 014C przed 014E; brak skracania retencji wcześniej |
| MinIO niedostępny z T630 | Test connectivity w 014B; firewall/Tailscale |
| `t630-data` nadal za duży | Rzadszy harmonogram lub wykluczenie z daily tar |
| Klucze Restic utracone | Secure backup hasła poza repo; dokumentacja recovery |

## Child SPECs

| SPEC | Repo | Status | Opis |
|------|------|--------|------|
| SPEC-014A | homeserver-core | done | Zwolnienie miejsca — **55G avail** — [`SPEC-014A`](../SPEC-014A-t630-disk-reclaim-phase0.md) |
| SPEC-014B | homeserver-services (+ homeserver-core creds) | done | [`SPEC-014B`](../SPEC-014B-restic-minio-bucket-access.md) — bucket, user, LAN T630→G2 |
| SPEC-014C | homeserver-core | draft | [`SPEC-014C`](../SPEC-014C-restic-init-first-backup.md) — install, init, pierwszy backup P0 |
| SPEC-014D | homeserver-core | draft | [`SPEC-014D`](../SPEC-014D-restic-cron-paths.md) — cron, retencja, P1/P2 |
| SPEC-014E | workspace + homeserver-core | planned | Restore drill, skrócenie lokalnej retencji, runbook |

## Powiązanie z EPIC-006

```text
EPIC-014 (ten epik) ──blokuje cutover──► EPIC-006 Forgejo MVP
```

Forgejo może być planowane równolegle (SPECs 006A draft), ale **produkcyjny cutover** i pełne backupy Forgejo wymagają działającego Restic → MinIO.
