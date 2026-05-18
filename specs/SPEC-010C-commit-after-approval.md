# SPEC-010C: Commit po approval

Parent: [EPIC-010](epics/EPIC-010-approval-pr-flow.md)
Status: review
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: infra

## Cel

Wymusić, że `git commit` w task worktree może wykonać tylko skrypt `task-git-commit` po zgodnym stanie `task.json` i evencie `approval_granted` dla gate `commit`.

## Zakres

### In scope

- Rola `approval-workflow` instalująca `approval-check`, `task-git-commit` i wspólną bibliotekę.
- Lokalny test fixture `.tasks/<task-id>/events.jsonl`.
- Aktualizacja `worktree-create`, żeby zapisywał provenance taska.

### Out of scope

- Deploy na T630.
- Push i PR Forgejo (SPEC-010D).

## Pliki / obszary

### Write

- `homeserver-services/roles/approval-workflow/`
- `homeserver-services/roles/worktree/files/worktree-create`
- `homeserver-services/tests/test_approval_workflow.py`

## Definition of Done

- [x] `approval-check --gate commit` odmawia bez approval.
- [x] `approval-check --gate commit` akceptuje zgodny event i stan.
- [x] `task-git-commit` tworzy commit i ustawia `awaiting_push_approval`.
- [x] Próba bez świeżej weryfikacji nie jest uznawana za done.

## Test plan

1. `python3 -m pytest -q tests/test_approval_workflow.py`
2. `python3 -m py_compile roles/approval-workflow/files/approval_lib.py roles/approval-workflow/files/approval-check roles/approval-workflow/files/task-git-commit`
3. `bash -n roles/worktree/files/worktree-create`

## Test plan (wykonany)

| Komenda/scenariusz | Kiedy | Oczekiwany wynik | Wynik rzeczywisty | Dowód/link | Wyjątki/notatki |
|--------------------|-------|------------------|-------------------|------------|-----------------|
| `python3 -m pytest -q tests/test_approval_workflow.py tests/test_forgejo_bot_commands.py tests/test_worktree_scripts.py` | 2026-05-18 | Wszystkie testy zielone | `10 passed in 0.94s` | homeserver-services | Brak deployu |
| `python3 -m py_compile roles/approval-workflow/files/approval_lib.py roles/approval-workflow/files/approval-check roles/approval-workflow/files/task-git-commit roles/approval-workflow/files/approval-push roles/forgejo-bot/files/commands.py roles/forgejo-bot/files/worker.py` | 2026-05-18 | Exit 0 | Exit 0 | homeserver-services | Python 3.9 compatible |
| `bash -n roles/worktree/files/worktree-create roles/worktree/files/worktree-remove` | 2026-05-18 | Exit 0 | Exit 0 | homeserver-services | Skrypty Python sprawdzane przez `py_compile`, nie `bash -n` |

## Rollback

Usunąć rolę `approval-workflow` z playbooka i cofnąć skrypt `worktree-create`; bez deployu zmiana nie wpływa na T630.

## Work log

- [SPEC-010C/D/E 2026-05-18](../docs/worklog/EPIC-010/SPEC-010CDE-2026-05-18-approval-workflow.md)
