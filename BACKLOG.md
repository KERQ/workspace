# BACKLOG

Priorytetyzacja pracy w workspace. Elementy przechodzą przez EPIC → SPEC zanim trafią do implementacji.

## Now

- [ ] EPIC-002 (draft): deploy orchestration dla multi-repo Ansible

## Next

- [ ] Uporządkować deploy orchestration — skrypty w workspace, check granic, bez deployu na hostach
- [ ] SPEC-003C: `scripts/deploy-g2.sh` (brak; `ops-run.sh` woła nieistniejący skrypt)

## Done (ostatnio)

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
