# SPEC-008B: difit — pinned Docker image

Parent: [EPIC-008](epics/EPIC-008-worktree-difit.md)
Status: done
Repo: homeserver-services

## Cel

Obraz `homeserver-difit:5.0.1` i skrypt `difit-preview <worktree-path>` → serwer na `127.0.0.1:4966`.

## Test plan

```bash
ssh t630 'difit-preview /srv/worktrees/homeserver-services-epic008-smoke'
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4966/
ssh t630 difit-stop
```
