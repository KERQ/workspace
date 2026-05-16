# EPIC-001: AI-Native Workspace foundation

Status: done
Owner: karolkurek
Risk: low
Repos: workspace (meta), brak zmian w repo domenowych w tej fazie

## Cel

Ustanowić root workspace: pliki operacyjne, specs, contracts MVP, szablony ADR/runbook/checks oraz podstawowe kontrakty między repo — **bez deployu**, **bez zmian infrastrukturalnych**, **bez dotykania sekretów**.

## Kontekst

- Decyzja: single workspace context + multi-repo execution ([`PROJEKT.md`](../../PROJEKT.md)).
- Faza 1 planu wdrożenia AI-Native Workspace Operating Model (Etap 0).
- Istniejące repo pozostają w `~/repos/`; workspace je widzi przez symlinki.

## Repo impact matrix

| Repo | Impact | Uwagi |
|------|--------|-------|
| workspace | write | Jedyny cel implementacji Fazy 1 |
| homeserver-core | none | Tylko odczyt ścieżek playbooków przy draft kontraktów |
| homeserver-services | none | j.w. |
| life-platform | none | j.w. |
| investment-research | none | — |
| openclaw-control-plane | none | — |

## In scope

- `PROJEKT.md`, `BACKLOG.md`, `AGENTS.md`, `README.md`
- `specs/` — README, templates, ten EPIC
- `contracts/` — MVP (deploy, ansible, services, secrets, repos)
- `docs/adr/`, `docs/runbooks/` — README + template ADR
- `scripts/checks/` — README
- Symlinki do pięciu repo domenowych

## Out of scope

- Deploy, restart usług, Ansible w repo domenowych
- Forgejo, OpenClaw `/v1`, difit
- Zmiany w repo domenowych (→ osobny SPEC poza EPIC-001)

## Kontrakty między repo

- [`contracts/deploy/t630-deploy-order.yml`](../../contracts/deploy/t630-deploy-order.yml)
- [`contracts/deploy/g2-deploy-order.yml`](../../contracts/deploy/g2-deploy-order.yml)
- [`contracts/ansible/role-ownership.yml`](../../contracts/ansible/role-ownership.yml)
- [`contracts/services/ports.yml`](../../contracts/services/ports.yml)
- [`contracts/secrets/scopes.yml`](../../contracts/secrets/scopes.yml)
- [`contracts/repos/repositories.yml`](../../contracts/repos/repositories.yml)

## Kolejność wdrożenia

1. SPEC-001A — skeleton (root + symlinki)
2. SPEC-001B — contracts MVP
3. SPEC-001C — templates SPEC/EPIC
4. SPEC-001D — AGENTS.md
5. SPEC-001E — spełnione przez SPEC-002 (pierwszy realny SPEC workspace)
6. SPEC-002 — consistency checks + commit/push workspace

## Global Definition of Done

- [x] Struktura katalogów workspace istnieje
- [x] Pliki bazowe i templates istnieją
- [x] Kontrakty MVP istnieją (draft)
- [x] Symlinki do 5 repo działają
- [x] SPEC-001E — spełnione przez SPEC-002 (zmiana domenowa → osobny SPEC, BACKLOG Next)
- [x] `git init` + commit + push `origin` (https://github.com/KERQ/workspace.git)

## Global test plan

1. `ls -la` symlinków — wskazują na `../<repo>`.
2. Brak plików z wartościami sekretów w workspace.
3. Agent może odczytać `AGENTS.md` + `PROJEKT.md` i zna flow pracy.
4. Draft `g2-deploy-order` — świadomość braku `homeserver-services/playbooks/g2.yml` lokalnie.

## Rollback

Usunięcie katalogów/plików utworzonych w workspace (poza istniejącym `PLAN.md`) oraz symlinków. Repo domenowe nietknięte.

## Approval gates

| Gate | Status |
|------|--------|
| Start Fazy 1 | zaakceptowany plan |
| Deploy | N/A w tym EPIC |
| Commit workspace | done (`ef7e011`, push `87800f5`) |

## Child SPECs

| SPEC | Repo | Status | Opis |
|------|------|--------|------|
| SPEC-001A-workspace-skeleton | workspace | done | Root files, README, symlinki |
| SPEC-001B-contracts-mvp | workspace | done | 5 YAML + contracts/README |
| SPEC-001C-spec-templates | workspace | done | EPIC/SPEC templates |
| SPEC-001D-agent-rules | workspace | done | AGENTS.md |
| SPEC-001E-first-real-change-selection | workspace | done | Zastąpione przez SPEC-002 (pierwszy realny SPEC workspace) |
| SPEC-002-workspace-consistency-checks | workspace | done | Check struktury, commit, push GitHub |
