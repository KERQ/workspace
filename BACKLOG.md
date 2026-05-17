# BACKLOG

Priorytetyzacja pracy w workspace. Elementy przechodzą przez `docs/ideas/` → BACKLOG → EPIC → SPEC zanim trafią do implementacji.

## Źródła strategiczne

- [`docs/ideas/ai_native_workspace_plan.md`](docs/ideas/ai_native_workspace_plan.md) — AI-Native Workspace Operating Model.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](docs/ideas/openclaw_architektura_forgejo_github_backup.md) — OpenClaw + Forgejo + GitHub backup.
- [`docs/ideas/ai_driven_worflow.md`](docs/ideas/ai_driven_worflow.md) — wizja i standardy AI-Driven Workflow (wcześniejszy model monorepo).

## Now

- [ ] [EPIC-014](specs/epics/EPIC-014-restic-minio-offbox-backup.md): Restic → MinIO + zwolnienie miejsca na T630 *(draft, blokuje cutover Forgejo)*
  - [SPEC-014A](specs/SPEC-014A-t630-disk-reclaim-phase0.md) *in_progress* — retencja HA, runbook phase0
  - Audyt: ~91% `/`, ~44G w `/opt/backups` (HA ~40G), ~16G reclaimable Docker images.
  - **Faza 0:** retencja HA, opcj. prune/legacy — cel **≥20 GB wolne** na `/`.
  - **Faza 1:** Restic → MinIO na G2 (`/mnt/seagate`), restore drill, potem skrócenie lokalnej retencji.
- [ ] [EPIC-006](specs/epics/EPIC-006-forgejo-mvp.md): Forgejo MVP / lokalny Git system of record dla jednego repo *(draft, cutover po EPIC-014)*
  - Forgejo + PostgreSQL przez Tailscale/Caddy.
  - Organizacja `KERQ`, wyłączona publiczna rejestracja.
  - Repo pilotażowe: `homeserver-services`.
  - `origin = Forgejo`, `github = GitHub` jako ręczny remote bez automatycznego mirror.
  - SSH push/pull smoke test, branch testowy i PR.
  - **Must-have:** backup Forgejo (DB dump + data) przez **Restic → MinIO** (docelowo G2 lub dedykowany bucket), nie tylko lokalne tar w `/opt/backups`.
  - Lokalny dump awaryjny krótkiej retencji OK; kanoniczny backup off-box = Restic/MinIO.
  - Audyt miejsca na dysku T630 przed cutover (obecnie ~91% `/`, głównie `/opt/backups`).
- [ ] EPIC-007: OpenClaw Gateway `/v1` + LibreChat/LobeChat
  - `/v1/models` i `/v1/chat/completions`.
  - Dostęp tylko loopback/tailnet/private ingress + Caddy auth.
  - LibreChat/LobeChat jako custom OpenAI endpoint do `openclaw/default`.
  - Wyłączona memory/RAG po stronie UI; OpenClaw memory jako jedyne źródło pamięci agentów.
  - Ograniczone tools: bez sekretów, deployu, merge i protected push.

## Next

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
- [ ] Przegląd zainstalowanych/działając usług i aplikacji na T630 i G2. Weryfikacja/przygotowanie dashboardu (one-pager) pokazującego linki do uruchomienia jeśli webowa oraz stan palikacji/suługi. 

## Icebox

- [ ] Git submodules zamiast symlinków (jeśli okaże się potrzebne)
- [ ] Nix devshell dla narzędzi agentów (bez zmiany OS)
- [ ] `/openclaw fix` z PR comment.
- [ ] `ultrareview` jako PR command.
- [ ] Quota widget / push notifications.
- [ ] SwarmClaw ops dashboard / council / autoloop.
- [ ] GitHub mirror tylko po merge/status pass.
