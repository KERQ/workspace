# SPEC-014C: T630 — instalacja Restic, init repo i pierwszy backup (P0)

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: draft
Repo: homeserver-core (+ workspace: runbook)
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-014B](SPEC-014B-restic-minio-bucket-access.md) (bucket, user, LAN, `/etc/restic/credentials.env`)
Blokuje: [SPEC-014D](SPEC-014D-restic-cron-paths.md) *(planowany)* — cron i pozostałe zestawy ścieżek

## Cel

Na T630 zainstalować **restic**, zainicjować **zaszyfrowane** repozytorium S3 na MinIO G2 i wykonać **pierwszy ręczny snapshot** zestawu **P0** (`/opt/backups`) — dowód, że off-box backup działa, zanim włączymy cron i skrócimy lokalną retencję (014D/E).

## Kontekst

- [SPEC-014A](SPEC-014A-t630-disk-reclaim-phase0.md) — `/opt/backups` ~14G HA + inne (~5 dni retencji).
- [SPEC-014B](SPEC-014B-restic-minio-bucket-access.md) — backend: `s3:http://192.168.1.19:19000/restic-backups`, user `restic-t630`.
- Lokalne backupy cron (`roles/backup`) **nadal działają** — Restic je tylko kopiuje off-box.
- Pierwszy backup P0 może trwać **długo** (dziesiątki GB) i obciążać LAN G2 — uruchomić w oknie maintenance.

## Decyzje

| Temat | Propozycja | Uwagi |
|-------|------------|-------|
| Repozytorium | **Jedno** repo w bucket `restic-backups` | Tagi `--tag` per zestaw przy backupie |
| `RESTIC_REPOSITORY` | `s3:http://192.168.1.19:19000/restic-backups` | Zgodnie z 014B |
| S3 path-style | `AWS_S3_FORCE_PATH_STYLE=true` | Wymagane dla MinIO |
| Pierwszy zestaw | **P0 tylko:** `/opt/backups` | P1/P2 w 014D |
| Retencja Restic | **Nie** w tym SPEC | Polityka `forget` w 014D |
| Skrócenie lokalnej retencji HA | **Zakaz** do 014E | Po restore drill |
| Instalacja | pakiet `restic` (apt) lub pinned binary | Preferuj apt jeśli wersja ≥ 0.16 |

## Zakres

### In scope

1. **Rola Ansible** `homeserver-core/roles/restic` (nowa):
   - pakiet `restic`,
   - katalog `/etc/restic/` (`credentials.env` z 014B + `excludes.txt`),
   - skrypt `restic-backup-p0.sh` (ręczny pierwszy backup),
   - opcjonalnie `restic-init.sh` (idempotentny `restic init` jeśli repo puste).
2. **Playbook** `t630.yml` — rola `restic`, tag `restic`.
3. **`restic init`** — jednorazowo z silnym `RESTIC_PASSWORD` (Vault / host_vars lokalne).
4. **Pierwszy backup ręczny** `/opt/backups` z tagiem `t630-backups`.
5. **Weryfikacja:** `restic snapshots`, `restic stats` (bez dumpu sekretów).
6. **Runbook:** `docs/runbooks/t630-restic-first-backup.md`.
7. **Worklog** w `docs/worklog/EPIC-014/`.

### Out of scope

- Cron / systemd timer → **014D**.
- Backup P1 (`t630-config`, openclaw) i P2 → **014D**.
- `restic forget` / polityka retencji → **014D**.
- Restore drill → **014E**.
- Skracanie `backup_ha_retention_days` lub `find -delete` w `/opt/backups`.
- Backup G2 hosta do tego repo.

## Pliki / obszary

### Read

- [SPEC-014B](SPEC-014B-restic-minio-bucket-access.md)
- `homeserver-core/roles/backup/` (ścieżki lokalne)
- `homeserver-core/playbooks/t630.yml`
- [EPIC-014 — ścieżki MVP](epics/EPIC-014-restic-minio-offbox-backup.md)

### Write (implementacja)

| Repo | Pliki (propozycja) |
|------|-------------------|
| `homeserver-core` | `roles/restic/{defaults,tasks,templates}/`, `handlers/main.yml` |
| `homeserver-core` | `playbooks/t630.yml` — dodać rolę `restic` |
| `homeserver-core` | `inventory/group_vars/t630_servers.yml` — `restic_*` (bez haseł) |
| `workspace` | ten SPEC, runbook, worklog |

### Forbidden

- `RESTIC_PASSWORD`, klucze MinIO w Git.
- `restic init` z hasłem w historii shell (`set +o history` / Ansible `no_log: true`).
- Usuwanie plików z `/opt/backups` w tym SPEC.

## Zmienne Ansible (propozycja, bez sekretów)

```yaml
# group_vars/t630_servers.yml
restic_enabled: true
restic_config_dir: /etc/restic
restic_credentials_file: "{{ restic_config_dir }}/credentials.env"
restic_excludes_file: "{{ restic_config_dir }}/excludes.txt"
restic_backup_tag_p0: t630-backups
restic_p0_paths:
  - /opt/backups
```

Sekrety w `inventory/host_vars/t630.yml` (gitignored lokalnie):

```yaml
restic_password: "<vault>"
# AWS_* jeśli nie tylko w credentials.env z 014B
```

## Wykluczenia backupu (`excludes.txt`)

```
**/.git
**/node_modules
**/.npm
**/cache
**/*.tmp
**/.openclaw.legacy-*
```

(Doprecyzować w roli; nie backupować legacy po SPEC-014A.)

## Do zrobienia

- [ ] SPEC-014B done (connectivity + creds na T630)
- [ ] Rola `restic` + tag w playbooku
- [ ] `ansible-playbook playbooks/t630.yml --syntax-check`
- [ ] Deploy roli (`APPROVE_DEPLOY=yes`)
- [ ] `restic init` (Ansible task lub runbook — `no_log`)
- [ ] Ręczny pierwszy backup P0 (`restic-backup-p0.sh` lub ad-hoc)
- [ ] `restic snapshots` ≥ 1 snapshot z tagiem `t630-backups`
- [ ] Worklog + wyniki rozmiaru/czasu
- [ ] Oznaczyć SPEC-014C done w EPIC/BACKLOG

## Definition of Ready

- [ ] SPEC-014B Definition of Done spełnione
- [ ] `RESTIC_PASSWORD` wygenerowane i zapisane poza Git (Vault + kopia recovery użytkownika)
- [ ] `/etc/restic/credentials.env` na T630 kompletne (`RESTIC_REPOSITORY`, AWS keys)
- [ ] Okno maintenance (pierwszy backup P0 może zająć >30 min)
- [ ] Approval: `APPROVE_DEPLOY=yes` + explicit na pierwszy backup

## Definition of Done

- [ ] `restic version` na T630 OK
- [ ] `restic -r $RESTIC_REPOSITORY snapshots` pokazuje ≥1 snapshot (`t630-backups`)
- [ ] `restic check` (quick lub full — wynik w worklog; exit 0)
- [ ] Na G2: dane w bucket `restic-backups` (rozmiar > 0; `mc du` lub console)
- [ ] Lokalna retencja `/opt/backups` **bez zmian** względem stanu po 014A
- [ ] Runbook opublikowany; brak sekretów w logach worklog

## Test plan

### Preflight

```bash
ssh t630@192.168.1.20 '
  test -f /etc/restic/credentials.env && test "$(stat -c %a /etc/restic/credentials.env)" = 600
  curl -fsS http://192.168.1.19:19000/minio/health/live
  du -sh /opt/backups
  df -h /
'
```

### Po deploy roli (bez init)

```bash
ssh t630@192.168.1.20 'restic version; ls -la /etc/restic/'
```

### Init (jednorazowo — nie logować haseł)

```bash
# Preferowane: Ansible z no_log, albo interaktywnie na T630:
ssh -t t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  restic init 2>&1 | tail -3'
# Oczekiwane: "created restic repository" lub "already exists"
```

### Pierwszy backup P0

```bash
ssh t630@192.168.1.20 'sudo /usr/local/bin/restic-backup-p0.sh'
# lub ścieżka z roli Ansible
```

Monitorowanie postępu (osobna sesja):

```bash
ssh t630@192.168.1.20 'restic -r "$(grep RESTIC_REPOSITORY /etc/restic/credentials.env | cut -d= -f2-)" snapshots'
```

### Po backupie

```bash
ssh t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  restic snapshots --tag t630-backups; restic stats --mode raw-data; restic check'

ssh g2@192.168.1.19 'set -a; . /opt/homeserver-services/g2-config/minio/.env; set +a; \
  mc du local/restic-backups --depth 1'
```

### Kryterium sukcesu

```text
≥1 snapshot z tagiem t630-backups obejmujący /opt/backups.
restic check exit 0.
Brak błędów S3 (403, timeout) w logu backupu.
```

## Szacunek pierwszego backupu P0

| Metryka | Szacunek (2026-05-17) |
|---------|------------------------|
| Rozmiar źródła | ~15–20G (`/opt/backups` po 014A) |
| Czas | zależny od LAN; liczyć 30–90 min |
| Miejsce na G2 | dużo wolnego na Seagate — OK |

Jeśli backup trwa zbyt długo: rozważyć pierwszy run w nocy; **nie** przerywać bez potwierdzenia (może zostawić partial pack — `restic check`).

## Rollback

| Krok | Cofnięcie |
|------|-----------|
| Rola restic | Wyłączyć `restic_enabled: false` + redeploy |
| `restic init` | Repo na MinIO można usunąć przez `mc rm --recursive` (tylko jeśli puste/test); **utrata haseł = utrata danych** |
| Nieudany partial backup | `restic recover` / ponowny backup; nie usuwać lokalnych `/opt/backups` |

## Approval gates

| Gate | Wymagane |
|------|----------|
| Start implementacji | karolkurek |
| Deploy Ansible T630 `--tags restic` | `APPROVE_DEPLOY=yes` |
| `restic init` | explicit (hasło nieodwracalne bez kopii) |
| Pierwszy backup P0 (obciążenie sieci/dysk) | explicit |

## Wpływ na kolejne SPECs

```text
014C (ten SPEC) → 014D cron + P1/P2 ścieżki + restic forget
               → 014E restore drill + skrócenie lokalnej retencji HA
               → EPIC-006 cutover (wymaga działającego off-box backupu)
```

## Work log

<!-- docs/worklog/EPIC-014/SPEC-014C-YYYY-MM-DD-*.md -->

-

## Prompt plan

1. Zweryfikuj SPEC-014B done.
2. Zaimplementuj rolę `restic` w homeserver-core; syntax-check.
3. Deploy; `restic init` z `no_log`.
4. Uruchom backup P0 w oknie maintenance; zapisz czas/rozmiar w worklog.
5. `restic snapshots` + `restic check`.
6. Nie zmieniaj lokalnej retencji ani crona w tym SPEC.

## Na później

- Osobne repo/prefix dla Forgejo (`t630-forgejo`) po EPIC-006.
- Kompresja domyślna restic — domyślnie włączona; monitorować CPU T630 przy dużych backupach.
