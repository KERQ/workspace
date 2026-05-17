# SPEC-009D: Status check, smoke, runbook

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: done
Zależy od: [SPEC-009C](SPEC-009C-forgejo-bot-commands-openclaw.md)

## Zakres

- Status check Forgejo: **`OpenClaw Review`** — `pending` na start review, `success`/`failure` po zakończeniu (komendy `review`, `review tests`, `review privacy`; nie `summarize`).
- Runbook: [t630-forgejo-openclaw-bot.md](../docs/runbooks/t630-forgejo-openclaw-bot.md)
- `contracts/services/ports.yml` → `openclaw_forgejo_bot` (status check w `note`)
- Worklog: [SPEC-009D-2026-05-17](../docs/worklog/EPIC-009/SPEC-009D-2026-05-17-forgejo-bot-status-smoke.md)
- Obraz `homeserver-forgejo-bot:0.3.0`

## PAT (scope)

Status check wymaga **`write:repository`** na PAT `openclaw-bot` (endpoint `POST …/statuses/{sha}`). Kod bota **nie** wywołuje push ani `POST …/contents` — nadal zakazane operacyjnie.

## Smoke (E2E, 2026-05-17)

| Krok | Wynik |
|------|--------|
| PR #2 `test: SPEC-009D smoke` | Utworzony |
| `/openclaw review` | Komentarz `openclaw-bot` + status `success` |
| Commity na branchu PR | 1 (tylko marker smoke; bot nie dodał commitów przy review) |
