# SPEC-009B: Serwis `openclaw-forgejo-bot` + webhook

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: done
Zależy od: [SPEC-009A](SPEC-009A-forgejo-bot-user-token.md)

## Zakres

- Rola Ansible `homeserver-services/roles/forgejo-bot` (lub `openclaw-forgejo-bot`).
- Kontener na T630: `127.0.0.1:8091`, health `GET /health`.
- Env: `FORGEJO_BASE_URL`, `FORGEJO_BOT_TOKEN`, `FORGEJO_WEBHOOK_SECRET`, `OPENCLAW_BASE_URL`, `OPENCLAW_GATEWAY_TOKEN`.
- Caddy (life-platform): `handle /forgejo-bot/*` → `127.0.0.1:8091` (tylko tailnet).
- Webhook w repo `homeserver-services`: URL + secret, zdarzenia: `pull_request`, `issue_comment`.

## Smoke

- `curl http://127.0.0.1:8091/health` → 200.
- Test webhook z Forgejo (delivery log) → 200, wpis w logach bota.
