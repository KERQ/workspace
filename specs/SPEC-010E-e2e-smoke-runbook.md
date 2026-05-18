# SPEC-010E: E2E smoke approval-first

Parent: [EPIC-010](epics/EPIC-010-approval-pr-flow.md)
Status: review
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: docs | infra

## Cel

Spisać i przygotować lokalne elementy E2E: `worktree-create` -> `difit-preview` -> approval diff -> commit -> approval push/PR -> `/openclaw review`.

## Zakres

### In scope

- Hardening `worktree-create` / `worktree-remove`.
- Tryby `/openclaw review spec` i `/openclaw review quality`.
- Runbooki: authoring skilli, receiving review, verification-before-completion.

### Out of scope

- Faktyczny push/PR bez explicit approval.
- Deploy roli na T630.

## Definition of Done

- [x] Worktree ma provenance w `/srv/worktrees/.tasks/<task-id>/task.json`.
- [x] Cleanup odmawia usunięcia worktree bez provenance, chyba że operator wymusi manual cleanup.
- [x] OpenClaw bot rozpoznaje `/openclaw review spec` i `/openclaw review quality`.
- [x] Dokumenty opisują verification-before-completion i systematic debugging.

## Test plan

1. `python3 -m pytest -q tests/test_approval_workflow.py tests/test_forgejo_bot_commands.py tests/test_worktree_scripts.py`
2. `bash -n roles/worktree/files/worktree-create roles/worktree/files/worktree-remove`
3. `ansible-playbook --syntax-check playbooks/t630.yml` jeśli Ansible jest dostępny lokalnie.

## Test plan (wykonany)

| Komenda/scenariusz | Kiedy | Oczekiwany wynik | Wynik rzeczywisty | Dowód/link | Wyjątki/notatki |
|--------------------|-------|------------------|-------------------|------------|-----------------|
| `python3 -m pytest -q tests/test_approval_workflow.py tests/test_forgejo_bot_commands.py tests/test_worktree_scripts.py` | 2026-05-18 | Approval, bot commands i worktree smoke zielone | `10 passed in 0.94s` | homeserver-services | E2E T630 nieuruchamiany bez deploy/approval |
| `bash -n roles/worktree/files/worktree-create roles/worktree/files/worktree-remove` | 2026-05-18 | Exit 0 | Exit 0 | homeserver-services | Sprawdza bashowe wrappery worktree |
| `ansible-playbook --syntax-check playbooks/t630.yml` | 2026-05-18 | Playbook parsuje się poprawnie | Exit 0, `playbook: playbooks/t630.yml` | homeserver-services | Syntax-check, bez deployu |
| `python3` walidujący `contracts/approvals/task-artifact.example.json` i gate transitions YAML | 2026-05-18 | JSON/YAML spójne | `ok` | workspace | PyYAML dostępny lokalnie |

## Rollback

Wycofać zmiany w skryptach worktree, `forgejo-bot` i dokumentacji; bez deployu lokalna zmiana nie wpływa na T630.

## Work log

- [SPEC-010C/D/E 2026-05-18](../docs/worklog/EPIC-010/SPEC-010CDE-2026-05-18-approval-workflow.md)
