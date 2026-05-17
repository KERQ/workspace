# SPEC-009C: Komendy PR → OpenClaw `/v1`

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: done
Zależy od: [SPEC-009B](SPEC-009B-forgejo-bot-service-webhook.md)

## Zakres

| Trigger | Akcja |
|---------|--------|
| `pull_request` opened/synchronize | Auto-summary tylko gdy `FORGEJO_BOT_AUTO_SUMMARY=1` (domyślnie **wyłączone**) |
| Komentarz `/openclaw summarize` | Summary PR → komentarz bota |
| `/openclaw review` | Code review → komentarz |
| `/openclaw review tests` | Review pod kątem testów |
| `/openclaw review privacy` | Review pod kątem sekretów/PII |

- Pobranie diffu przez Forgejo API; limit rozmiaru (`FORGEJO_BOT_DIFF_MAX_CHARS`, domyślnie 80000).
- Wywołanie `POST /v1/chat/completions` (`OPENCLAW_MODEL`, domyślnie `openclaw/default`).
- Stały blok **security prompt** (untrusted input) w system message.
- Publikacja komentarza jako `openclaw-bot`.
- Kontener `network_mode: host` — dostęp do OpenClaw na `127.0.0.1:18789`.
- Obraz `homeserver-forgejo-bot:0.2.0`.

Implementacja: `homeserver-services/roles/forgejo-bot/files/` (`worker.py`, `commands.py`, `forgejo_api.py`, `openclaw_api.py`).

## Poza zakresem

- `/openclaw fix`, `/openclaw ultrareview`, `/openclaw run tests`
- Status check `OpenClaw Review` → [SPEC-009D](SPEC-009D-forgejo-bot-smoke-runbook.md)

## Smoke (2026-05-17)

| Test | Wynik |
|------|--------|
| `GET /health` | `version: 0.2.0` |
| Webhook `issue_comment` + `/openclaw summarize` na PR #1 | Komentarz `openclaw-bot` z podsumowaniem |
| `FORGEJO_BOT_AUTO_SUMMARY=0` | `pull_request` open/sync ignorowany |

Pełny smoke z żywym PR i komendą w UI — [SPEC-009D](SPEC-009D-forgejo-bot-smoke-runbook.md).
