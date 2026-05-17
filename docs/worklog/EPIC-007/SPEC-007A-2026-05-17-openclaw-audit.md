# Worklog: SPEC-007A — audyt OpenClaw (szkic)

**Data:** 2026-05-17  
**SPEC:** [SPEC-007A](../../specs/SPEC-007A-openclaw-audit-and-plan.md)  
**Status:** draft — checklist do wykonania na T630

## Kontekst

- EPIC-OCP-1 zarchiwizowany; delegacja UI → LibreChat (EPIC-007).
- Ten worklog uzupełniamy po wykonaniu checklisty audytu (bez sekretów w treści).

## Checklist audytu

| ID | Obszar | Status | Uwagi |
|----|--------|--------|-------|
| A | Gateway systemd | pending | |
| B | Config runtime | pending | |
| C | Agenci / workspace | pending | |
| D | Caddy / tailnet | pending | |
| E | OCP runtime (docker) | pending | |
| F | Ansible inventory | pending | |
| G | OCP repo validate/stage | pending | |

## Smoke `/v1`

| Test | Status | Uwagi |
|------|--------|-------|
| models loopback | pending | token: ustawiony tak/nie |
| chat loopback | pending | |
| models tailnet | pending | |
| auth bez Bearer | pending | |

## Dalsze kroki

1. Wykonać checklist na T630 + lokalnie.
2. Uzupełnić [openclaw-007-development-plan.md](../plans/openclaw-007-development-plan.md) §7–8.
3. Zamknąć SPEC-007A → przejść do SPEC-007B.
