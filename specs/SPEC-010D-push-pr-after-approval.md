# SPEC-010D: Push i PR po approval

Parent: [EPIC-010](epics/EPIC-010-approval-pr-flow.md)
Status: review
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: infra

## Cel

Wymusić, że `git push` i utworzenie PR Forgejo wykonuje tylko `approval-push` po gate `push_pr`, dodatnim `test_summary` i osobnym `approval_id`.

## Zakres

### In scope

- `approval-push --dry-run` jako bezpieczny smoke body PR.
- Walidacja `test_summary.exit_code == 0`.
- Body PR zawierające `spec_ref`, test summary i approval ids.

### Out of scope

- Merge PR.
- Deploy/restart po merge.
- UI Approve w LibreChat.

## Pliki / obszary

### Write

- `homeserver-services/roles/approval-workflow/files/approval-push`
- `homeserver-services/tests/test_approval_workflow.py`

## Definition of Done

- [x] `approval-push --dry-run` odmawia przy brakujących lub nieudanych testach.
- [x] `approval-push --dry-run` generuje body PR bez wykonania push.
- [x] W trybie realnym skrypt wymaga `FORGEJO_TOKEN`.

## Test plan

1. `python3 -m pytest -q tests/test_approval_workflow.py`
2. Fixture negatywny: `test_summary.exit_code != 0` -> `tests_not_successful`.

## Test plan (wykonany)

| Komenda/scenariusz | Kiedy | Oczekiwany wynik | Wynik rzeczywisty | Dowód/link | Wyjątki/notatki |
|--------------------|-------|------------------|-------------------|------------|-----------------|
| `python3 -m pytest -q tests/test_approval_workflow.py tests/test_forgejo_bot_commands.py tests/test_worktree_scripts.py` | 2026-05-18 | `approval-push` negatywny i dry-run pozytywny przechodzą | `10 passed in 0.94s` | homeserver-services | Brak realnego push/PR bez approval |
| `python3 -m py_compile roles/approval-workflow/files/approval_lib.py roles/approval-workflow/files/approval-check roles/approval-workflow/files/task-git-commit roles/approval-workflow/files/approval-push roles/forgejo-bot/files/commands.py roles/forgejo-bot/files/worker.py` | 2026-05-18 | Exit 0 | Exit 0 | homeserver-services | Brak błędów składni Python |

## Rollback

Wyłączyć rolę `approval-workflow` albo usunąć `approval-push` z `approval_bin_dir`; istniejące task artifacts pozostają audytowalne.

## Work log

- [SPEC-010C/D/E 2026-05-18](../docs/worklog/EPIC-010/SPEC-010CDE-2026-05-18-approval-workflow.md)
