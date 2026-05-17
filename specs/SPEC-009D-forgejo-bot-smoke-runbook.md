# SPEC-009D: Status check, smoke, runbook

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: planned
Zależy od: [SPEC-009C](SPEC-009C-forgejo-bot-commands-openclaw.md)

## Zakres

- Status check Forgejo: **`OpenClaw Review`** — pending na start review, success/failure po zakończeniu.
- Runbook: `workspace/docs/runbooks/t630-forgejo-openclaw-bot.md`
- `contracts/services/ports.yml` → `openclaw_forgejo_bot` (:8091)
- Worklog EPIC-009

## Smoke (E2E)

1. PR testowy na `homeserver-services`.
2. `/openclaw review` → komentarz + status check zielony/czerwony.
3. Bot **nie** tworzy commitów na branchu PR.
