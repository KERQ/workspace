# Runbook: T630 approval-first PR flow

## Cel

Przejść audytowalny cykl: worktree -> difit -> approval diff -> commit -> approval push/PR -> review OpenClaw, bez automerge i bez deployu.

## Wymagania

- Rola `worktree`, `difit`, `approval-workflow` wdrożona na T630.
- Repo ma mirror pod `/srv/repos/<repo>`.
- Task ma katalog `/srv/worktrees/.tasks/<task-id>/`.
- Commit, push/PR, deploy i restart wymagają explicit approval.

## Flow

```bash
# 1. Utwórz worktree i provenance
ssh t630 'SPEC_REF=workspace/specs/SPEC-010E-e2e-smoke-runbook.md worktree-create homeserver-services my-task origin/main'

# 2. Agent/operator robi patch w /srv/worktrees/homeserver-services-my-task

# 3. Uruchom testy i zapisz wynik w task.json/test.log
# Minimalny format: test_summary.command, test_summary.exit_code, opcjonalnie log_path.

# 4. Pokaż diff
ssh t630 difit-preview /srv/worktrees/homeserver-services-my-task

# 5. Po review człowieka dopisz approval_granted gate=diff_review, potem przejście do awaiting_commit_approval.
# 6. Po osobnym approval commit:
ssh t630 task-git-commit --task-id my-task --message "feat: my task"

# 7. Po osobnym approval push/PR:
ssh t630 approval-push --task-id my-task --dry-run
ssh t630 approval-push --task-id my-task

# 8. W PR: /openclaw review spec albo /openclaw review quality
```

## Kryteria sukcesu

- `approval-check --task-id <id> --gate commit` odmawia przed approval i przechodzi po approval.
- `task-git-commit` zapisuje `commit_recorded` i ustawia `awaiting_push_approval`.
- `approval-push --dry-run` pokazuje body PR z `spec_ref`, test summary i approval ids.
- PR review działa przez `/openclaw review spec` albo `/openclaw review quality`.

## Red flags

- Ręczny `git commit` / `git push` z pominięciem skryptów.
- PR bez `test_summary` albo z `exit_code != 0`.
- Merge, deploy albo restart wykonany przez agenta.
