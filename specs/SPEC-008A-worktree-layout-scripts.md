# SPEC-008A: Layout worktree + skrypty

Parent: [EPIC-008](epics/EPIC-008-worktree-difit.md)
Status: done
Repo: homeserver-services

## Cel

`/srv/repos`, `/srv/worktrees`, klon `homeserver-services` z Forgejo, skrypty `worktree-create` / `worktree-remove`.

## Test plan

```bash
ssh t630 worktree-create homeserver-services epic008-smoke origin/main
test -d /srv/worktrees/homeserver-services-epic008-smoke/.git
worktree-remove homeserver-services epic008-smoke
```
