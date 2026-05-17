# SPEC-014B: G2 MinIO — bucket Restic i dostęp z T630

Parent: [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)
Status: done
Repo: homeserver-services (+ homeserver-core: zmienne T630, connectivity)
Owner: karolkurek
Risk: medium
Type: infra
Blokuje: [SPEC-014C](SPEC-014C-restic-init-first-backup.md) — init Restic i pierwszy backup

## Cel

Przygotować **backend S3** dla Restic na istniejącym MinIO G2: dedykowany bucket, użytkownik IAM z minimalnymi uprawnieniami, sieć **T630 → G2 API**, sekrety poza Git — bez jeszcze instalacji `restic` ani pierwszego snapshotu (to SPEC-014C).

## Kontekst

- [SPEC-014A](SPEC-014A-t630-disk-reclaim-phase0.md) done — T630 ~55G wolne na `/`.
- MinIO G2: kontener `minio`, API `127.0.0.1:19000`, console `127.0.0.1:19001`, dane `/mnt/seagate/data/minio` ([SPEC-015](SPEC-015-t630-g2-service-dashboard.md)).
- Rola `homeserver-services/roles/trading` — zarządza MinIO i bucketami tradingowymi przez `mc`.
- Obecnie API jest zbindowane tylko na **loopback** — T630 nie może pisać do MinIO bez zmiany sieci lub proxy.

## Decyzje (do potwierdzenia przed implementacją)

| Temat | Propozycja | Alternatywa |
|-------|------------|-------------|
| Instancja MinIO | Istniejący stack trading (`:19000`) | Osobna instancja — **odrzucone** (nadmiar) |
| Nazwa bucketu | `restic-backups` | — |
| Użytkownik S3 | `restic-t630` (dedicated, nie root) | Root MinIO — **odrzucone** |
| Dostęp sieciowy T630→API | **LAN:** bind API `192.168.1.19:19000`; console zostaje `127.0.0.1:19001` | Tailscale-only bind; Caddy vhost + auth |
| Endpoint Restic (014C) | `s3:http://192.168.1.19:19000/restic-backups` | path-style wymagany dla MinIO |
| Sekrety | Ansible Vault / pliki host-only (`0600`) | Brak sekretów w Git |

**Rekomendacja:** LAN bind — prosty `restic` i `curl` health z T630; sieć domowa za routerem; użytkownik bucket-scoped.

## Zakres

### In scope

1. **Bucket** `restic-backups` na MinIO G2 (mc `mb --ignore-existing`).
2. **Użytkownik** `restic-t630` + policy **tylko** `restic-backups` (read/write/list; bez innych bucketów trading).
3. **Sieć:** API MinIO osiągalne z T630 (`192.168.1.20` → `192.168.1.19:19000`).
4. **Ansible** (homeserver-services): rozszerzenie roli MinIO lub osobne taski `restic-minio` pod tagiem `restic-minio`.
5. **Ansible** (homeserver-core): szablon `/etc/restic/credentials.env` na T630 (placeholders; wartości z Vault przy deploy).
6. **Test connectivity** z T630 (health + lista bucketu / probe S3) — wynik w worklog.
7. **Runbook** operacyjny: `docs/runbooks/g2-minio-restic-backend.md`.

### Out of scope

- Instalacja `restic`, `restic init`, pierwszy backup → **SPEC-014C**.
- Cron, retencja snapshotów → **SPEC-014D**.
- Restore drill, skrócenie lokalnej retencji HA → **SPEC-014E**.
- Backup `investment-research` do tego bucketu.
- Eksponowanie MinIO na internet / publiczny DNS.

## Pliki / obszary

### Read

- `homeserver-services/roles/trading/tasks/minio.yml`
- `homeserver-services/roles/trading/defaults/main.yml`
- `homeserver-services/roles/trading/templates/minio-docker-compose.yml.j2`
- `homeserver-services/inventory/host_vars/g2.yml`
- `homeserver-core/inventory/hosts.yml` (T630 `192.168.1.20`, G2 `192.168.1.19`)
- [EPIC-014](epics/EPIC-014-restic-minio-offbox-backup.md)

### Write (implementacja — po approval)

| Repo | Pliki (propozycja) |
|------|-------------------|
| `homeserver-services` | `defaults`: `restic_minio_*`; `tasks/restic-minio.yml`; bucket w mc; user/policy; opcj. `trading_minio_api_bind` → LAN |
| `homeserver-core` | `roles/restic` (szkielet) lub `host_vars/t630` + template `credentials.env.j2`; playbook tag `restic-minio` |
| `workspace` | ten SPEC, runbook, worklog |

### Forbidden

- `MINIO_ROOT_*` / `RESTIC_PASSWORD` w commitach Git.
- Zmiana lifecycle trading bucketów poza dodaniem `restic-backups`.
- Publiczny bind `0.0.0.0` bez uzasadnienia — preferuj `192.168.1.19`.

## Do zrobienia

- [x] Decyzja sieci: **LAN** (`192.168.1.19:19000`)
- [x] Bucket `restic-backups` (mc)
- [x] Użytkownik `restic-t630` + policy `restic-t630-rw`
- [x] Bind API MinIO na LAN
- [x] `/etc/restic/credentials.env` na T630 (mode 600, sudo do odczytu)
- [x] Testy connectivity z T630
- [x] Runbook + worklog
- [x] EPIC-014 zaktualizowany

## Definition of Ready

- [x] SPEC-014A done
- [x] Decyzja: LAN bind
- [x] Sekret `restic-t630` w `inventory/.secrets/` (kontroler, gitignored)
- [x] Deploy G2 + T630 wykonany

## Definition of Done

- [x] Bucket `restic-backups` na G2
- [x] Test negatywny: `raw-gdelt` → Access Denied
- [x] T630 → health LAN OK
- [x] T630 → `mc ls g2restic/restic-backups` (sudo + creds)
- [x] `/etc/restic/credentials.env` wdrożony
- [x] Runbook opublikowany
- [x] Worklog: [SPEC-014B-2026-05-17](../docs/worklog/EPIC-014/SPEC-014B-2026-05-17-restic-minio-bucket-access.md)

## Test plan

### Preflight (read-only)

```bash
# G2 — stan MinIO
ssh g2@192.168.1.19 'curl -fsS http://127.0.0.1:19000/minio/health/live && docker ps --filter name=minio --format "{{.Names}} {{.Status}}"'

# T630 — czy widać G2 na LAN (przed bind LAN może failować)
ssh t630@192.168.1.20 'curl -fsS --connect-timeout 3 http://192.168.1.19:19000/minio/health/live || echo FAIL_LAN'
```

### Po wdrożeniu (G2)

```bash
ssh g2@192.168.1.19 'set -a; . /opt/homeserver-services/g2-config/minio/.env; set +a; \
  mc alias set local http://127.0.0.1:19000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null && \
  mc ls local/restic-backups && mc admin user list local | rg restic-t630'
```

### Po wdrożeniu (T630 → G2)

```bash
# Bez echo haseł — użyć /etc/restic/credentials.env
ssh t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  curl -fsS http://192.168.1.19:19000/minio/health/live && \
  mc alias set g2restic "http://192.168.1.19:19000" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" && \
  mc ls g2restic/restic-backups'
```

### Test negatywny (scope policy)

```bash
# restic-t630 nie powinien listować np. raw-gdelt
ssh t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  mc ls g2restic/raw-gdelt 2>&1 | rg -i "access|denied|not found" || echo UNEXPECTED_ACCESS'
```

## Sekrety (konwencja)

| Sekret | Gdzie | Uwagi |
|--------|-------|-------|
| MinIO root | G2 `g2-config/minio/.env` | Istniejące; tylko do admin mc |
| `restic-t630` access key / secret | Vault → T630 `/etc/restic/credentials.env` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| `RESTIC_PASSWORD` | T630 ten sam plik lub osobny | Używany w 014C przy `restic init`; **nie** w 014B |

Przykład **szablonu** (bez wartości w Git):

```bash
# /etc/restic/credentials.env (mode 600)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export RESTIC_REPOSITORY=s3:http://192.168.1.19:19000/restic-backups
# RESTIC_PASSWORD=...  # ustawić w 014C przy init
```

## Rollback

| Zmiana | Cofnięcie |
|--------|-----------|
| LAN bind API | Przywrócić `trading_minio_api_bind: 127.0.0.1` + redeploy compose |
| Bucket / user | Usunąć user policy; bucket zostaje (dane puste do 014C) |
| T630 credentials | `rm /etc/restic/credentials.env` |

## Approval gates

| Gate | Wymagane |
|------|----------|
| Start implementacji | karolkurek |
| Zmiana bind MinIO (krótka przerwa API) | explicit + `APPROVE_DEPLOY=yes` |
| Deploy G2 playbook `--tags restic-minio` | `APPROVE_DEPLOY=yes` |
| Zapis credentials na T630 | `APPROVE_DEPLOY=yes` |

## Wpływ na kolejne SPECs

```text
014B (ten SPEC) → 014C restic init + pierwszy backup
               → 014D cron + ścieżki
               → 014E restore drill + skrócenie /opt/backups
```

## Work log

- [2026-05-17 — Restic MinIO bucket access](../docs/worklog/EPIC-014/SPEC-014B-2026-05-17-restic-minio-bucket-access.md)

## Prompt plan

1. Potwierdź wariant sieci (LAN zalecany).
2. Rozszerz rolę MinIO w `homeserver-services`; syntax-check.
3. Deploy G2; utwórz bucket i użytkownika.
4. Deploy szablonu creds na T630 (Vault).
5. Wykonaj test plan; worklog.
6. Nie instaluj `restic` ani nie rób `restic init` w tym SPEC.

## Na później

- Szyfrowanie repo Restic (hasło w 014C).
- Monitoring nieudanych backupów (014D).
- Osobny bucket dla Forgejo jeśli wymagana izolacja polityki (opcjonalnie prefix w tym samym bucket).
