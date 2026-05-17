# BACKLOG

Priorytetyzacja pracy w workspace. Elementy przechodzą przez `docs/ideas/` → BACKLOG → EPIC → SPEC zanim trafią do implementacji.

## Źródła strategiczne

- [`docs/ideas/ai_native_workspace_plan.md`](docs/ideas/ai_native_workspace_plan.md) — AI-Native Workspace Operating Model.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](docs/ideas/openclaw_architektura_forgejo_github_backup.md) — OpenClaw + Forgejo + GitHub backup.
- [`docs/ideas/ai_driven_worflow.md`](docs/ideas/ai_driven_worflow.md) — wizja i standardy AI-Driven Workflow (wcześniejszy model monorepo).

## Now

- [ ] [EPIC-009](specs/epics/EPIC-009-forgejo-bot.md): Forgejo bot read/comment/review
  - [x] [SPEC-009A](specs/SPEC-009A-forgejo-bot-user-token.md) — `openclaw-bot`, PAT, webhook secret — [runbook](docs/runbooks/t630-forgejo-openclaw-bot.md)
  - [ ] [SPEC-009B](specs/SPEC-009B-forgejo-bot-service-webhook.md) — serwis `:8091`, Caddy, webhook
  - [ ] [SPEC-009C](specs/SPEC-009C-forgejo-bot-commands-openclaw.md) — `/openclaw summarize|review*`, `/v1`
  - [ ] [SPEC-009D](specs/SPEC-009D-forgejo-bot-smoke-runbook.md) — status check, smoke, runbook
  - Zakazy MVP: no write repo, no merge, no deploy, no `/openclaw fix`.

## Next

- [ ] [SPEC-007G](specs/SPEC-007G-librechat-openclaw-llm-picker.md): LibreChat — wybór wariantu LLM (np. Sonnet vs Opus, Codex vs Gemini) per agent lub preset
  - Poza 007F (tam tylko agent, nie model). Wymaga mapowania preset → `claude-cli/sonnet` vs `claude-cli/opus` (lub LiteLLM alias) + audyt kosztów/uprawnień.
  - Alternatywa krótkoterminowa: zmiana `openclaw_agent_model_overrides` w Ansible + deploy `openclaw`.
- [x] [SPEC-007F](specs/SPEC-007F-librechat-openclaw-agent-picker.md): LibreChat — wybór agentów OpenClaw (orchestrator, research, personal, finance, smart home; bez coding/infra)
- [ ] **Dashboard web (T630/G2)** — aplikacja WWW, stan usług na żywo *(nie one-pager z SPEC-015)*
  - Szkic SPEC: **SPEC-017** (do utworzenia) — read-only MVP; źródła: `docker ps`, porty, health HTTP; hosty T630 + G2.
  - Wejście: [SPEC-015](specs/SPEC-015-t630-g2-service-dashboard.md) (audyt), [runbook](docs/runbooks/t630-g2-service-dashboard.md).
  - Auth: Tailscale + Caddy; bez deployu/restartu z UI.
  - Ingress: [SPEC-016](specs/SPEC-016-t630-caddy-unify-docker.md) done — jeden Caddy na T630.
  - **Nie blokuje** EPIC-014 / EPIC-006; po stabilnym backupie lub równolegle.
- [x] [EPIC-008](specs/epics/EPIC-008-worktree-difit.md): worktree + `difit` preview przed commitem — **done**
  - [x] [SPEC-008A](specs/SPEC-008A-worktree-layout-scripts.md) — `/srv/repos`, `/srv/worktrees`, skrypty
  - [x] [SPEC-008B](specs/SPEC-008B-difit-docker-image.md) — obraz `homeserver-difit:5.0.1`
  - [x] [SPEC-008C](specs/SPEC-008C-difit-tailscale-serve.md) — Tailscale Serve TCP `:4966` (bez Caddy `/diff/`)
  - [x] [SPEC-008D](specs/SPEC-008D-smoke-runbook-contracts.md) — runbook, contracts
- [ ] EPIC-010: approval-first commit/push/PR workflow
  - Flow: SPEC ready -> worktree -> tests -> patch -> test results -> `difit` preview.
  - Commit dopiero po approval.
  - Push/PR dopiero po osobnym approval.
  - Bot robi summary/review; człowiek merge'uje.

## Done (ostatnio)

- [x] [EPIC-006](specs/epics/EPIC-006-forgejo-mvp.md): Forgejo MVP / lokalny Git system of record dla `homeserver-services` (006A–E, PR smoke merged, backup Restic active)
- [x] [EPIC-014](specs/epics/EPIC-014-restic-minio-offbox-backup.md): Restic → MinIO G2 + reclaim T630 (014A–E, 59G wolne na `/`)
- [x] EPIC-005: migracja runtime path G2 -> `/opt/homeserver-services`
- [x] SPEC-005E: cleanup symlinków + runbooki
- [x] SPEC-005D: Ansible docelowe ścieżki + deploy G2
- [x] SPEC-005B: migracja ścieżek na G2 only
- [x] SPEC-005A: zmienna `homeserver_runtime_root` w Ansible (bez zmiany hostów)
- [x] SPEC-004: runbook local paths → homeserver-services
- [x] EPIC-002: deploy orchestration (workspace deploy/, syntax-check default)
- [x] SPEC-003C: deploy-g2.sh, deploy-t630-safe.sh, check-compose (homeserver-services)
- [x] SPEC-003B: `playbooks/g2.yml` w homeserver-services
- [x] SPEC-003: ansible playbook sanity check (`homeserver-services`)
- [x] EPIC-001: AI-Native Workspace foundation
- [x] SPEC-002: workspace consistency checks + commit/push
- [x] Workspace na GitHub: https://github.com/KERQ/workspace

## Later

- [ ] EPIC-011: selektywny GitHub backup/mirror
  - Refaktor dokumentacji repozytoriów raz struktury plikjów
  - Najpierw ręczny `git push github main --tags`.
  - Test mirror na pustym repo testowym.
  - Push mirror dla `homeserver-core` i `homeserver-services`.
  - Rozważyć `openclaw-control-plane`.
  - Nie włączać domyślnie dla `investment-research`.
  - Branch filter: `main`, `release/*`.
  - Monitoring błędów mirror sync.
- [ ] EPIC-012: uzupełnić workspace tooling i kontrakty
  - `scripts/bootstrap.sh`, `scripts/sync.sh`, `scripts/test-all.sh`, `scripts/check-all.sh`.
  - Testy deploy boundaries w `deploy/tests/`.
  - Osobne checki: deploy boundaries, inventory drift.
  - Rozszerzyć `contracts/` o API/events/ansible-vars, gdy pojawią się realne integracje.
- [ ] EPIC-013: domenowe backlogi dla `life-platform`, `investment-research`, `openclaw-control-plane`
  - Dodać tylko po osobnych analizach w `docs/ideas/`.
  - `investment-research` zachowuje hard privacy i nie dostaje domyślnego GitHub mirror.
- [x] [SPEC-015](specs/SPEC-015-t630-g2-service-dashboard.md): audyt usług T630/G2 + one-pager ([runbook](docs/runbooks/t630-g2-service-dashboard.md)) — **nie** aplikacja web
- [x] [SPEC-016](specs/SPEC-016-t630-caddy-unify-docker.md): T630 — jeden Caddy (Docker), `caddy.service` wyłączony ([worklog](docs/worklog/OPS/SPEC-016-2026-05-17-t630-caddy-unify.md))

## Icebox

- [x] **EPIC-OCP-1** (Personal Control Plane `apps/ui`+`apps/api`) — **zarchiwizowany 2026-05-17**; delegacja UI → EPIC-007 / LibreChat. Kod w `openclaw-control-plane/apps/` zamrożony; ADR w tym repo.
- [ ] Git submodules zamiast symlinków (jeśli okaże się potrzebne)
- [ ] Nix devshell dla narzędzi agentów (bez zmiany OS)
- [ ] `/openclaw fix` z PR comment.
- [ ] `ultrareview` jako PR command.
- [ ] Quota widget / push notifications.
- [ ] SwarmClaw ops dashboard / council / autoloop.
- [ ] GitHub mirror tylko po merge/status pass.
- [ ] Wprowadzić zmiany w reutingu dla aplikjacji web aby linki https://t630.colobus-micro.ts.net/git/ działały tak: https://git.t630.colobus-micro.ts.net/
