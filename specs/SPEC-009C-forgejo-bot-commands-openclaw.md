# SPEC-009C: Komendy PR → OpenClaw `/v1`

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: planned
Zależy od: [SPEC-009B](SPEC-009B-forgejo-bot-service-webhook.md)

## Zakres

| Trigger | Akcja |
|---------|--------|
| `pull_request` opened/synchronize | Auto-summary (opcjonalnie wyłącz flagą) lub tylko na komendę |
| Komentarz `/openclaw summarize` | Summary PR → komentarz bota |
| `/openclaw review` | Code review → komentarz |
| `/openclaw review tests` | Review pod kątem testów |
| `/openclaw review privacy` | Review pod kątem sekretów/PII |

- Pobranie diffu przez Forgejo API; limit rozmiaru (truncate + informacja w komentarzu).
- Wywołanie `POST /v1/chat/completions` (`model: openclaw/default` lub dedykowany agent review).
- Stały blok **security prompt** (untrusted input) w system message.
- Publikacja komentarza jako `openclaw-bot`.

## Poza zakresem

- `/openclaw fix`, `/openclaw ultrareview`, `/openclaw run tests`

## Smoke

- Otwórz testowy PR, komentarz `/openclaw summarize` → komentarz bota w < 2 min (zależnie od modelu).
