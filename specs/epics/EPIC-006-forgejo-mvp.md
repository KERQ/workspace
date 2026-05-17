# EPIC-006: Forgejo MVP — lokalny Git system of record (jedno repo)

Status: draft
Owner: karolkurek
Risk: medium
Repos: homeserver-core, homeserver-services, workspace (docs/contracts)
Blokuje: —
Zablokowany przez: [EPIC-014](EPIC-014-restic-minio-offbox-backup.md) (cutover produkcyjny — po Restic/MinIO i ≥20 GB wolne na T630 `/`)

## Cel

Postawić **Forgejo + PostgreSQL** na **T630** jako lokalny system Git/PR/review dla **jednego** repozytorium pilotażowego (`homeserver-services`), z dostępem wyłącznie przez **Tailscale + Caddy**, bez automatycznego mirror do GitHub.

Po zakończeniu epiku:

- PR workflow działa lokalnie w Forgejo dla `homeserver-services`.
- `origin` wskazuje Forgejo; `github` pozostaje ręcznym remote (bez push mirror).
- Dane Forgejo mają backup (DB + volume).
- GitHub **nie** jest jeszcze automatycznym mirror (to EPIC-011).

## Kontekst

- [`BACKLOG.md`](../../BACKLOG.md) — sekcja **Now**, EPIC-006.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md) — etap 1, §5 porty, §6 layout T630, §18 must-have.
- [`docs/ideas/ai_native_workspace_plan.md`](../../docs/ideas/ai_native_workspace_plan.md) — Etap 2.
- [`contracts/services/ports.yml`](../../contracts/services/ports.yml) — `forgejo_web` (planned, port 3000).
- [`contracts/repos/repositories.yml`](../../contracts/repos/repositories.yml) — polityki mirror per repo.

## Decyzje wstępne (do potwierdzenia w SPEC-006A)

| Temat | Propozycja MVP | Uwagi |
|-------|----------------|-------|
| Host | T630 | Zgodnie z architekturą OpenClaw/Forgejo |
| Repo pilotażowe | `homeserver-services` | Największy flow dev/deploy; już na GitHub |
| Baza Forgejo | PostgreSQL (nie SQLite) | Zgodnie z dokumentem architektonicznym |
| Web UI | port `3000`, domena `git.t630.<tailnet>` | Caddy reverse proxy + auth |
| Git SSH | port `2222` | `git@t630 -p 2222` / tailnet |
| Layout danych | `/srv/ai-stack/forgejo/` lub równoważnik w istniejącym stacku | Do ustalenia w 006A względem obecnego Ansible |
| Właściciel compose/Ansible | **TBD** — `homeserver-core` vs `homeserver-services` | Caddy w core; usługi kontenerowe często w services |

## Repo impact matrix

| Repo | Impact | Uwagi |
|------|--------|-------|
| `homeserver-core` | write | Caddy vhost `git.*`, ewentualnie firewall/Tailscale |
| `homeserver-services` | write | Compose Forgejo + PostgreSQL, role/playbook T630 |
| `workspace` | write | Ten EPIC, child SPECs, runbook, aktualizacja `contracts/` |
| `life-platform` | none | Poza zakresem MVP |
| `investment-research` | none | Poza zakresem MVP; mirror GitHub wyłączony na stałe |
| `openclaw-control-plane` | read | Polityki repo — bez zmian w MVP |

## In scope

- Forgejo + PostgreSQL na T630 (Docker Compose).
- Dostęp web i SSH tylko przez tailnet (Caddy + auth/session).
- Organizacja Forgejo `KERQ`.
- Import / mirror jednorazowy repo `homeserver-services` z GitHub (lub push istniejącego bare).
- Konfiguracja lokalnych remote: `origin` = Forgejo, `github` = GitHub (ręczny push).
- Wyłączona publiczna rejestracja użytkowników.
- Smoke: SSH, branch testowy, PR w Forgejo UI.
- Backup Forgejo (PostgreSQL dump + volume `data/`) — **kanonicznie przez Restic → MinIO** ([EPIC-014](EPIC-014-restic-minio-offbox-backup.md)); lokalny dump tylko krótka retencja awaryjna.
- Runbook operacyjny w `docs/runbooks/`.
- Aktualizacja kontraktu portów (`forgejo_web.status: active`).

## Out of scope

- Automatyczny push mirror do GitHub → **EPIC-011**.
- OpenClaw Gateway `/v1`, LibreChat → **EPIC-007**.
- `difit`, worktree, `/srv/worktrees` → **EPIC-008**.
- Forgejo bot (`openclaw-bot`, webhooks, `/openclaw review`) → **EPIC-009**.
- Approval-first agent commit/PR flow → **EPIC-010**.
- Migracja pozostałych repo (`homeserver-core`, `life-platform`, `investment-research`).
- CI w Forgejo (Actions) — później.
- `/openclaw fix`, ultrareview, SwarmClaw.

## Guardrails

```text
- no auto-deploy bez APPROVE_DEPLOY=yes
- no secrets w Git (PAT, .env, tokeny Forgejo)
- no public exposure Forgejo poza tailnet
- no GitHub push mirror w tym epiku
- no agent write/merge — tylko człowiek
- investment-research poza pilotem
```

## Kolejność wdrożenia (child SPECs)

```text
006A (compose + Ansible skeleton)
  → 006B (Caddy + Tailscale ingress)
  → 006C (org KERQ + import homeserver-services)
  → 006D (remotes + SSH/PR smoke)
  → 006E (backup + runbook + contracts)
```

Każdy child SPEC: **test plan (smoke/check) przed apply**, zgodnie z `PROJEKT.md` §test-first.

## Global Definition of Done

- [ ] Wszystkie child SPECs w statusie `done` lub świadomie anulowane
- [ ] Forgejo UI dostępne na `git.t630.<tailnet>` (tailnet only)
- [ ] `homeserver-services` ma działający PR w Forgejo (branch testowy → PR → merge ręczny)
- [ ] Lokalny checkout: `git remote -v` pokazuje `origin` → Forgejo, `github` → GitHub
- [ ] Brak skonfigurowanego automatycznego mirror do GitHub
- [ ] Backup Forgejo zweryfikowany (restore drill opisany w runbooku)
- [ ] `contracts/services/ports.yml` — `forgejo_web.status: active`
- [ ] Runbook: `docs/runbooks/t630-forgejo-mvp.md` (lub równoważna nazwa)
- [ ] ADR jeśli wybór layoutu `/srv/ai-stack/` vs istniejący stack wymaga trwałej decyzji

## Global test plan

### Faza A — przed deploy (syntax / config)

1. `docker compose config` dla stacku Forgejo (lokalnie lub na T630 po sync).
2. `ansible-playbook --syntax-check` dla playbooków dotykających T630/Forgejo.
3. Walidacja Caddyfile (jeśli osobny check w core).
4. Contract check: porty zgodne z `contracts/services/ports.yml`.

### Faza B — po deploy (smoke na T630)

```bash
# Web UI (z maszyny w tailnecie)
curl -sS -o /dev/null -w "%{http_code}" https://git.t630.<tailnet>/

# SSH Forgejo
ssh -p 2222 git@git.t630.<tailnet>

# Git flow (checkout lokalny homeserver-services)
cd ~/repos/homeserver-services
git fetch origin
git checkout -b test/forgejo-smoke
git commit --allow-empty -m "test: forgejo smoke"
git push origin test/forgejo-smoke
# Utworzyć PR w UI Forgejo, merge ręczny
```

### Faza C — backup

1. Wykonać backup według runbooku.
2. Potwierdzić obecność dumpu DB i archiwum volume (bez przywracania produkcji w MVP — wystarczy checklist + opcjonalny test na kopii).

## Rollback

| Poziom | Działanie |
|--------|-----------|
| Przed cutover remote | Zatrzymać kontenery Forgejo; usunąć vhost Caddy; `origin` pozostaje GitHub |
| Po cutover, przed merge smoke PR | Przywrócić `origin` na GitHub w lokalnym checkout; Forgejo zostaje jako read-only mirror |
| Po awarii danych | Restore z backupu DB + volume (runbook 006E) |

Pełny rollback hosta poza zakresem — osobny runbook disaster recovery.

## Approval gates

| Gate | Wymagane approval |
|------|-------------------|
| Start EPIC (akceptacja szkicu) | karolkurek |
| SPEC-006A–E (implementacja w repo) | per SPEC review |
| Deploy T630 (compose up, Caddy reload) | **manual**, `APPROVE_DEPLOY=yes` |
| Zmiana `origin` na maszynach deweloperskich | karolkurek (świadomy cutover) |
| Merge smoke PR | karolkurek (ręcznie w Forgejo UI) |

## Ryzyka

| Ryzyko | Mitigacja |
|--------|-----------|
| Push mirror przypadkowo włączony | Explicit out of scope; weryfikacja w 006C/006D |
| Sekrety w repo importowanym | Audit przed importem; `.gitignore` / vault poza Git |
| Konflikt portów 3000/2222 | Sprawdzenie `ss -lntp` przed deploy; kontrakt portów |
| Utrata danych Forgejo | Backup 006E przed cutover produkcyjnym |
| Downtime GitHub podczas pilotażu | GitHub pozostaje `github` remote; Forgejo równolegle |

## Child SPECs

| SPEC | Repo | Status | Opis |
|------|------|--------|------|
| SPEC-006A | homeserver-services (+ core jeśli wspólny stack) | planned | Compose Forgejo + PostgreSQL, zmienne Ansible, `--syntax-check` |
| SPEC-006B | homeserver-core | planned | Caddy vhost `git.*`, Tailscale, wyłączona rejestracja publiczna |
| SPEC-006C | workspace + manual ops | planned | Org `KERQ`, import `homeserver-services`, ustawienia instancji |
| SPEC-006D | workspace runbook | planned | `origin`/`github` remotes, SSH smoke, branch testowy + PR |
| SPEC-006E | workspace + homeserver-services | planned | Backup DB+data, runbook, aktualizacja `contracts/services/ports.yml` |

> Child SPECs utworzymy po akceptacji tego EPIC (kolejność: 006A → 006E).

## Powiązane epiki (później)

| EPIC | Zależność od 006 |
|------|------------------|
| EPIC-007 OpenClaw `/v1` | Nie blokuje; równoległy po stabilnym Forgejo |
| EPIC-008 worktree + difit | Wymaga działającego Git (Forgejo jako origin) |
| EPIC-009 Forgejo bot | Wymaga działającego Forgejo + PR |
| EPIC-010 approval PR flow | Wymaga 006 + 008 + 009 |
| EPIC-011 GitHub mirror | **Po** stabilnym Forgejo MVP |

## Źródła

- Forgejo Docker: https://forgejo.org/docs/latest/admin/installation/docker/
- Forgejo mirrors (świadomie **nie** w MVP): https://forgejo.org/docs/latest/user/repo-mirror/
