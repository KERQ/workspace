# SPEC-007E — tool policies, runbook, OCP stop (2026-05-17)

## Wykonane

- Audyt: `openclaw/default` → orchestrator OK dla UI; `coding_agent` usunięty z listy modeli LibreChat.
- Runbook: [t630-openclaw-gateway-librechat.md](../../runbooks/t630-openclaw-gateway-librechat.md) — host network, Caddy `redir`, troubleshooting.
- Kontrakty: `openclaw_gateway`, `librechat` → `active` (bez zmian).
- OCP: `docker compose stop` w `/opt/openclaw-control-plane/runtime`.

## Poprawki z sesji (przed 007E formalnie)

| Problem | Fix |
|---------|-----|
| Biały ekran `/chat` | Caddy `redir /chat /chat/ permanent` |
| Timeout LibreChat | `network_mode: host` + gateway `127.0.0.1:18789` |
| `agent_id` | `ENDPOINTS=custom`, `interface.agents: false`, modelSpecs OpenClaw |

## EPIC-007

Status epiku: **done** (007D LobeChat opcjonalny / cancelled).
