# Worklog: SPEC-007A — audyt OpenClaw na T630

**Data:** 2026-05-17  
**SPEC:** [SPEC-007A](../../specs/SPEC-007A-openclaw-audit-and-plan.md)  
**Host:** `t630@192.168.1.20` (LAN)  
**Status:** done (audyt wykonany; smoke PASS)

## Kontekst

- EPIC-OCP-1 zarchiwizowany; delegacja UI → LibreChat (EPIC-007).
- Audyt **read-only** + smoke `/v1` (token użyty na hoście — **nie** logowany w tym dokumencie).

## Checklist audytu

| ID | Obszar | Status | Uwagi |
|----|--------|--------|-------|
| A | Gateway systemd | **OK** | `active`; OpenClaw **2026.5.3-1**; `127.0.0.1:18789`; HTTP 200 na `/` |
| B | Config runtime | **OK** | port=18789, chatCompletions=true, **auth=true**; `openclaw doctor` complete (7 plugins loaded) |
| C | Agenci / workspace | **OK** | 9 agentów (`main`, `infra_agent`, …, `orchestrator`); default **orchestrator**; `~/.openclaw/workspace/` istnieje |
| D | Caddy / tailnet | **OK** | `https://t630.colobus-micro.ts.net/openclaw/` → 200; `/v1/models` bez Bearer → **401** |
| E | OCP runtime (docker) | **OK** | Tylko `openclaw-control-plane-postgres` (:55432) + `redis` (:56379) — **brak** kontenerów OCP UI/API. Forgejo :3030/:2222 OK |
| F | Ansible inventory | **OK** | `openclaw_enabled: true` w `host_vars/t630.yml`; `ansible-playbook --syntax-check` PASS |
| G | OCP repo validate/stage | **OK** | `validate-policies.py` PASS; `stage-config.py --validate-only` PASS (lokalnie) |

### Porty aplikacji (nie OCP UI)

| Port | Proces | Uwaga |
|------|--------|-------|
| 3000 | `node server/index.js` | OpenClaw Studio (loopback) |
| 3001 | `cloudcli` | Osobna usługa node |
| 3002 | ClawSuite `vite preview` | `/clawsuite/` |
| 3030 | Forgejo | EPIC-006 |

## Smoke `/v1`

| Test | Status | Uwagi |
|------|--------|-------|
| models loopback | **PASS** | `first_model_id=openclaw`; token_present=true |
| chat loopback | **PASS** | HTTP 200; `openclaw/default` odpowiedział (smoke ping) |
| models tailnet | **PASS** | `https://t630.colobus-micro.ts.net/v1/models` → 200 z Bearer |
| auth bez Bearer | **PASS** | loopback i tailnet → **401** |

## Wnioski

1. **Reinstall OpenClaw nie jest potrzebny** — gateway działa, `/v1` + auth OK.
2. **EPIC-OCP-1 UI/API nie działa na T630** — tylko Postgres/Redis OCP; bezpieczne do **stop** w 007E po LibreChat (oszczędność zasobów).
3. **LibreChat** może używać `host.docker.internal:18789` lub `172.17.0.1:18789` — gateway tylko na loopback.
4. **Drift config:** runtime ma auth i chatCompletions — zgodne z szablonem Ansible; pełny diff nie wykonywany (ryzyko sekretów).
5. **Następny SPEC:** 007B (Caddy `/chat/`), potem 007C (LibreChat).

## Dalsze kroki

- [x] Uzupełniono [openclaw-007-development-plan.md](../plans/openclaw-007-development-plan.md) §7–8
- [ ] Owner review planu → zamknięcie SPEC-007A w status `done`
- [ ] SPEC-007B — Caddy ingress `/chat/`
