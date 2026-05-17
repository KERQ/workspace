# Runbook: OpenClaw Gateway + LibreChat (T630)

**EPIC:** [EPIC-007](../specs/epics/EPIC-007-openclaw-gateway-librechat.md)  
**Status:** szkic (ingress w SPEC-007B; LibreChat w 007C)

## Działające URL-e (tailnet)

| Usługa | URL | Uwagi |
|--------|-----|-------|
| OpenClaw Gateway UI | `https://t630.colobus-micro.ts.net/openclaw/` | Control UI gatewaya |
| OpenClaw API `/v1` | `https://t630.colobus-micro.ts.net/v1/...` | Bearer `OPENCLAW_GATEWAY_TOKEN` |
| ClawSuite (POC) | `https://t630.colobus-micro.ts.net/clawsuite/` | **Nie** używać `:3002` bez Caddy |
| Forgejo | `https://t630.colobus-micro.ts.net/git/` | |
| LibreChat | `https://t630.colobus-micro.ts.net/chat/` | Po SPEC-007C |
| OpenClaw Studio | `http://127.0.0.1:3000/` | Tylko loopback; tunel SSH lub lokalnie na T630 |

## Czego nie używać

- `http://192.168.1.20:3000/` — Studio nasłuchuje tylko na `127.0.0.1` → connection refused.
- `http://<tailscale-ip>:3002/` — brak shim `/api/*` → ClawSuite wisi na „Initializing…”.

## Smoke `/v1`

```bash
export OPENCLAW_GATEWAY_TOKEN='…'   # z vault / host_vars — nie logować

curl -sS https://t630.colobus-micro.ts.net/v1/models \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" | jq .
```

## Deploy Caddy (life-platform)

Po zmianie `domains/home/configs/caddy/Caddyfile`:

```bash
# Wymaga APPROVE_DEPLOY=yes — patrz playbook home-assistant, tag caddy
docker compose -f domains/home/configs/docker-compose.yml up -d --force-recreate caddy
```

## LibreChat

→ [SPEC-007C](../specs/SPEC-007C-librechat-compose.md) *(planowany)*
