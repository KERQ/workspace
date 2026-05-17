# EPIC-009: Forgejo bot — read/comment/review

Status: planned
Owner: karolkurek
Risk: medium
Repos: homeserver-services, workspace (opcjonalnie life-platform ingress)
Blokuje: [EPIC-010](EPIC-010-approval-pr-flow.md) *(planowany)*
Zablokowany przez: [EPIC-006](EPIC-006-forgejo-mvp.md) **done**, [EPIC-007](EPIC-007-openclaw-gateway-librechat.md) **done**, [EPIC-008](EPIC-008-worktree-difit.md) **done**

## Cel

Bot **`openclaw-bot`** w Forgejo: webhooki PR/komentarze → OpenClaw `/v1` → komentarze i status check na PR — **bez** zapisu do repo, merge ani deploy.

Po epiku:

- Użytkownik Forgejo `openclaw-bot` + tokeny read/comment (sekrety w `host_vars`, nie w Git).
- Usługa `openclaw-forgejo-bot` na T630 (`127.0.0.1:8091`), webhook z Forgejo.
- Komendy MVP w PR: `/openclaw summarize`, `/openclaw review`, `/openclaw review tests`, `/openclaw review privacy`.
- Status check **`OpenClaw Review`** (pending → success/failure po odpowiedzi).
- Runbook + wpis w `contracts/services/ports.yml`.

## Decyzje MVP

| Temat | Wartość |
|-------|---------|
| Host | T630 |
| Repo pilotażowe | `homeserver-services` (org KERQ) |
| Forgejo API | `http://127.0.0.1:3030` (loopback) |
| OpenClaw | `http://127.0.0.1:18789/v1/chat/completions` + gateway token |
| Bot HTTP | `127.0.0.1:8091` — webhook tylko z loopback / Caddy internal (brak publicznego internetu) |
| Webhook URL | `https://t630.colobus-micro.ts.net/forgejo-bot/hooks` (Caddy → :8091) lub Serve — w 009B |
| Tokeny | read + comment (jeden PAT MVP wystarczy jeśli scope obejmuje oba) |
| `/openclaw fix` | **out of scope** |
| Write repo / merge / deploy | **zakazane** |

## Child SPECs

| SPEC | Status | Opis |
|------|--------|------|
| [SPEC-009A](../SPEC-009A-forgejo-bot-user-token.md) | done | Użytkownik `openclaw-bot`, PAT, webhook secret w host_vars — [runbook](../docs/runbooks/t630-forgejo-openclaw-bot.md) |
| [SPEC-009B](../SPEC-009B-forgejo-bot-service-webhook.md) | planned | Obraz/compose, webhook receiver, Caddy `/forgejo-bot/` |
| [SPEC-009C](../SPEC-009C-forgejo-bot-commands-openclaw.md) | planned | Handlery zdarzeń + komendy → `/v1` + komentarze |
| [SPEC-009D](../SPEC-009D-forgejo-bot-smoke-runbook.md) | planned | Status check, smoke PR, runbook, contracts |

## Kolejność

```text
009A (konto + sekrety)
  → 009B (serwis + webhook + ingress)
  → 009C (logika komend + OpenClaw)
  → 009D (smoke + runbook)
```

## Guardrails

```text
- NO write repo / NO merge / NO deploy przez bota
- NO /openclaw fix w MVP
- NO secrets w Git
- Webhook secret weryfikowany (HMAC Forgejo)
- Prompt review: diff/PR body = untrusted input (§12.4 architektury)
- investment-research poza pilotem
```

## Źródła

- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md) — §12 OpenClaw Forgejo Bot
- [`BACKLOG.md`](../../BACKLOG.md) — EPIC-009
