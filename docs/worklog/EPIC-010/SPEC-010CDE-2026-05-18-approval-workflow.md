# SPEC-010C/D/E — approval workflow, review modes, verification docs

Data: 2026-05-18
Repo: `homeserver-services`, `workspace`

## Zmiany

- Dodano rolę `approval-workflow` z `approval-check`, `task-git-commit`, `approval-push` i wspólną biblioteką.
- Utwardzono `worktree-create` / `worktree-remove`: provenance taska, guard worktree/submodule, bezpieczny cleanup tylko dla workflow-created worktree.
- Rozszerzono `forgejo-bot` o `/openclaw review spec` i `/openclaw review quality`.
- Dodano zasady `verification-before-completion`, systematic debugging oraz standard repo-local skills.
- Usunięto ograniczenie EPIC-010, że automatyzacja ma być zawężona do `homeserver-services`; to repo jest referencyjne, nie jedyne.

## Weryfikacja

```bash
cd /Users/karolkurek/repos/homeserver-services
python3 -m pytest -q tests/test_approval_workflow.py tests/test_forgejo_bot_commands.py tests/test_worktree_scripts.py
# 10 passed in 0.94s

python3 -m py_compile roles/approval-workflow/files/approval_lib.py roles/approval-workflow/files/approval-check roles/approval-workflow/files/task-git-commit roles/approval-workflow/files/approval-push roles/forgejo-bot/files/commands.py roles/forgejo-bot/files/worker.py
# exit 0

bash -n roles/worktree/files/worktree-create roles/worktree/files/worktree-remove
# exit 0

ansible-playbook --syntax-check playbooks/t630.yml
# playbook: playbooks/t630.yml
```

```bash
cd /Users/karolkurek/repos/workspace
python3 - <<'PY'
import json
from pathlib import Path
import yaml
root = Path('contracts/approvals')
json.load((root / 'task-artifact.example.json').open())
states = yaml.safe_load((root / 'task-states.yml').read_text())
gates = yaml.safe_load((root / 'gates.yml').read_text())
allowed = {g['id'] for g in gates['gates']}
for t in states['transitions']:
    if 'required_gate' in t:
        assert t['required_gate'] in allowed, t
print('ok')
PY
# ok
```

## Nie wykonano

- Brak deployu na T630.
- Brak realnego commit/push/PR.
- Brak restartu usług.
