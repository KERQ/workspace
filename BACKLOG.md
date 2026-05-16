# BACKLOG

Priorytetyzacja pracy w workspace. Elementy przechodzą przez EPIC → SPEC zanim trafią do implementacji.

## Now

- [ ] EPIC-005: migracja runtime path G2 → `/opt/homeserver-services` (005D spec ready — czeka akceptacja/deploy)
- [ ] SPEC-005D: Ansible docelowe ścieżki + deploy G2 ([spec](specs/SPEC-005D-deploy-new-runtime-path.md))
- [x] SPEC-005A: zmienna `homeserver_runtime_root` w Ansible (bez zmiany hostów)

## Next

- [ ] SPEC-005B: migracja ścieżek na G2 only (maintenance, APPROVE_DEPLOY)
- [ ] SPEC-005D/E: deploy + cleanup

## Done (ostatnio)

- [x] SPEC-004: runbook local paths → homeserver-services
- [x] EPIC-002: deploy orchestration (workspace deploy/, syntax-check default)
- [x] SPEC-003C: deploy-g2.sh, deploy-t630-safe.sh, check-compose (homeserver-services)
- [x] SPEC-003B: `playbooks/g2.yml` w homeserver-services
- [x] SPEC-003: ansible playbook sanity check (`homeserver-services`)
- [x] EPIC-001: AI-Native Workspace foundation
- [x] SPEC-002: workspace consistency checks + commit/push
- [x] Workspace na GitHub: https://github.com/KERQ/workspace

## Later

- [ ] Wdrożyć Forgejo dla jednego repo pilotażowego
- [ ] Podłączyć LibreChat / OpenClaw (`/v1`)
- [ ] Dodać difit preview przed commitem
- [ ] Dodać Forgejo bot (read/comment/review)

## Icebox

- [ ] Git submodules zamiast symlinków (jeśli okaże się potrzebne)
- [ ] Nix devshell dla narzędzi agentów (bez zmiany OS)
- [ ] Pełne kontrakty: api, events, storage, models, data
