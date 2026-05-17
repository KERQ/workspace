# BACKLOG

Priorytetyzacja pracy w workspace. Elementy przechodzą przez `docs/ideas/` → BACKLOG → EPIC → SPEC zanim trafią do implementacji.

## Źródła strategiczne

- [`docs/ideas/ai_native_workspace_plan.md`](docs/ideas/ai_native_workspace_plan.md) — AI-Native Workspace Operating Model.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](docs/ideas/openclaw_architektura_forgejo_github_backup.md) — OpenClaw + Forgejo + GitHub backup.
- [`docs/ideas/ai_driven_worflow.md`](docs/ideas/ai_driven_worflow.md) — wizja i standardy AI-Driven Workflow (wcześniejszy model monorepo).

## Now

- [ ] [EPIC-007](specs/epics/EPIC-007-openclaw-gateway-librechat.md): OpenClaw Gateway `/v1` + LibreChat/LobeChat *(zastępuje zarchiwizowany EPIC-OCP-1 / `apps/ui`)*
  - [x] [SPEC-007A](specs/SPEC-007A-openclaw-audit-and-plan.md) — audyt OpenClaw + plan; gateway `/v1` smoke PASS; OCP tylko PG/Redis
  - [ ] [SPEC-007B](specs/SPEC-007B-openclaw-caddy-ingress.md) — Caddy `/chat/` → :3080 (deploy pending); audyt `/v1`
  - [ ] SPEC-007C — LibreChat Compose → `openclaw/default`, RAG/memory OFF
  - [ ] SPEC-007D — LobeChat (opcjonalnie)
  - [ ] SPEC-007E — tool policies, runbook, contracts
  - Gateway już na T630 (`:18789`, `chatCompletions` w szablonie); Caddy `/v1*` istnieje — epic domyka LibreChat + auth + dokumentację.

## Next

- [ ] **Dashboard web (T630/G2)** — aplikacja WWW, stan usług na żywo *(nie one-pager z SPEC-015)*
  - Szkic SPEC: **SPEC-017** (do utworzenia) — read-only MVP; źródła: `docker ps`, porty, health HTTP; hosty T630 + G2.
  - Wejście: [SPEC-015](specs/SPEC-015-t630-g2-service-dashboard.md) (audyt), [runbook](docs/runbooks/t630-g2-service-dashboard.md).
  - Auth: Tailscale + Caddy; bez deployu/restartu z UI.
  - Ingress: [SPEC-016](specs/SPEC-016-t630-caddy-unify-docker.md) done — jeden Caddy na T630.
  - **Nie blokuje** EPIC-014 / EPIC-006; po stabilnym backupie lub równolegle.
- [ ] EPIC-008: worktree + `difit` preview przed commitem
  - Ustalić `/srv/worktrees` albo lokalny odpowiednik w workspace.
  - Procedura worktree per task.
  - Pinned `difit` image.
  - Ręczny preview na testowym worktree.
  - Diff przez Tailscale + Basic Auth.
  - Flow approve / reject / modify.
- [ ] EPIC-009: Forgejo bot read/comment/review
  - Użytkownik `openclaw-bot` i token read/comment.
  - Webhook repo/org -> bot.
  - Komendy `/openclaw summarize`, `/openclaw review`, `/openclaw review tests`, `/openclaw review privacy`.
  - Komentarze i status check `OpenClaw Review`.
  - Zakazy MVP: no write repo, no merge, no deploy, no `/openclaw fix`.
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
