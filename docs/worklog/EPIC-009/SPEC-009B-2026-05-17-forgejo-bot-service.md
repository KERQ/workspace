# SPEC-009B — Forgejo bot service (2026-05-17)

## Wdrożone

- Rola `homeserver-services/roles/forgejo-bot`
- Obraz `homeserver-forgejo-bot:0.1.0`, kontener `openclaw-forgejo-bot` na `127.0.0.1:8091`
- Caddy `handle_path /forgejo-bot/*` → `:8091`
- Webhook w `KERQ/homeserver-services` (rejestracja admin CLI — PAT bota bez `write:repository`)

## Smoke

| Test | Wynik |
|------|--------|
| `curl http://127.0.0.1:8091/health` | 200 |
| POST `/hooks` + HMAC | 200 |
| `https://t630…/forgejo-bot/health` | 200 |
| POST bez podpisu przez Caddy | 401 |

## Następny

SPEC-009D — status check + pełny smoke (009C done — [worklog](SPEC-009C-2026-05-17-forgejo-bot-commands.md)).
