# SPEC-009C — komendy `/openclaw` + OpenClaw (2026-05-17)

## Wdrożone

- Obraz `homeserver-forgejo-bot:0.2.0`, moduły `worker`, `commands`, `forgejo_api`, `openclaw_api`
- Komendy: `summarize`, `review`, `review tests`, `review privacy`
- `network_mode: host` w compose (loopback OpenClaw)
- Env: `OPENCLAW_GATEWAY_TOKEN`, `OPENCLAW_MODEL`, `FORGEJO_BOT_DIFF_MAX_CHARS`, `FORGEJO_BOT_AUTO_SUMMARY` (domyślnie 0)
- Deploy: `ansible-playbook … --tags forgejo-bot -e forgejo_bot_force_rebuild=true`

## Smoke

| Test | Wynik |
|------|--------|
| `curl http://127.0.0.1:8091/health` | `0.2.0` |
| Symulowany webhook `issue_comment` + `/openclaw summarize` (PR #1) | Komentarz bota na Forgejo |

## Następny

SPEC-009D done — [worklog](SPEC-009D-2026-05-17-forgejo-bot-status-smoke.md).
