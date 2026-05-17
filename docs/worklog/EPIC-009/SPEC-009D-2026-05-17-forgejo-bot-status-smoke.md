# SPEC-009D — status check + smoke (2026-05-17)

## Wdrożone

- `forgejo_api.create_commit_status`, `get_pull`
- `worker`: pending → success/failure dla `review*`
- Env: `FORGEJO_BOT_STATUS_ENABLED`, `FORGEJO_BOT_STATUS_CONTEXT`
- Obraz `homeserver-forgejo-bot:0.3.0`

## PAT

Dodano `write:repository` (CLI `forgejo admin user generate-access-token`). Zsynchronizowano `forgejo_bot_token` w lokalnym `host_vars/t630.yml` (gitignored).

## Smoke

| Test | Wynik |
|------|--------|
| `GET /health` | `0.3.0` |
| PR #2 + `/openclaw review` | Komentarz + status `OpenClaw Review` success |
| Bot nie commituje przy review | 1 commit na PR (tylko plik smoke) |

## EPIC-009

Wszystkie child SPECs (009A–009D) done.
