# SPEC-007E: Tool policies, runbook, contracts, OCP runtime stop

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: done
Repo: workspace, homeserver-services
Owner: karolkurek
Risk: medium
Type: docs + infra
Zablokowany przez: [SPEC-007C](SPEC-007C-librechat-compose.md) **done** (LibreChat smoke OK)

## Cel

Domknąć EPIC-007: audyt polityk narzędzi dla ścieżki UI-delegacji (LibreChat → `/v1`), runbook operacyjny, kontrakty `active`, zatrzymanie martwego runtime OCP (Postgres/Redis bez UI/API).

## Audyt polityk (UI → `openclaw/default`)

| Model LibreChat | Agent OpenClaw | `ops_deploy` | `group:fs` | `group:runtime` | Werdykt MVP |
|-----------------|----------------|--------------|------------|-----------------|-------------|
| `openclaw/default` | `orchestrator` (default) | brak w allow | brak | brak | **OK** — delegacja chat |
| `openclaw/orchestrator` | `orchestrator` | j.w. | j.w. | j.w. | redundantny — **usunięty z UI** |
| `openclaw/coding_agent` | `coding_agent` | **allow** | **allow** | **allow** | **poza UI MVP** — nie eksponować |

Guardrails EPIC-007 (deploy, merge, sekrety z host_vars): domyślny agent **nie** ma `ops_deploy`, `group:fs`, `group:runtime`. Pełna lista: `homeserver-services/roles/openclaw/defaults/main.yml` → `openclaw_agent_tool_policies`.

**Decyzja:** LibreChat eksponuje wyłącznie `openclaw/default` w `librechat.yaml` (modelSpecs + lista modeli).

## OCP runtime (T630)

| Kontener | Akcja 007E | Uwagi |
|----------|------------|-------|
| `openclaw-control-plane-postgres` | `docker compose stop` | Projekt: `/opt/openclaw-control-plane/runtime` |
| `openclaw-control-plane-redis` | j.w. | Wolumeny **zachowane** |
| `apps/ui`, `apps/api` | brak na T630 | EPIC-OCP-1 archived |

## Runbook

- [docs/runbooks/t630-openclaw-gateway-librechat.md](../docs/runbooks/t630-openclaw-gateway-librechat.md) — zaktualizowany (ingress, LibreChat host network, troubleshooting).

## Kontrakty

- `contracts/services/ports.yml` — `openclaw_gateway.status: active`, `librechat.status: active` (już ustawione w 007C).

## Smoke (Definition of Done)

- [x] LibreChat: wiadomość testowa → odpowiedź (operator, 2026-05-17)
- [x] `/v1/models` + `/v1/chat/completions` przez tailnet
- [x] Tylko `openclaw/default` w selektorze LibreChat
- [x] OCP Postgres/Redis stopped
- [x] Runbook + worklog

## Rollback OCP

```bash
ssh t630 'cd /opt/openclaw-control-plane/runtime && docker compose start'
```
