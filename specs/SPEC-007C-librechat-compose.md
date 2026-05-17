# SPEC-007C: T630 — LibreChat Compose + OpenClaw endpoint

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: done
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-007B](SPEC-007B-openclaw-caddy-ingress.md) **done**
Blokuje: [SPEC-007E](SPEC-007E-openclaw-tool-policies-contracts.md) *(planowany)*

## Cel

Wdrożyć **LibreChat** na T630 (`127.0.0.1:3080`) z custom endpoint **OpenClaw** (`openclaw/default`), bez RAG/memory po stronie LibreChat; publiczny URL: `https://t630.colobus-micro.ts.net/chat/`.

## Decyzje

| Temat | Wartość |
|-------|---------|
| Obraz | `ghcr.io/danny-avila/librechat:latest` |
| MongoDB | `mongo:7`, volume `/srv/ai-stack/librechat/mongo` |
| Compose | `/opt/homeserver-services/t630-config/librechat/` |
| Gateway z LibreChat | `http://127.0.0.1:18789/v1` — `network_mode: host` (gateway tylko loopback; patrz 007E) |
| `DOMAIN_CLIENT` / `DOMAIN_SERVER` | `https://t630.colobus-micro.ts.net/chat` |
| Rejestracja | `ALLOW_REGISTRATION=true` (tailnet); wyłączyć po utworzeniu konta |
| RAG / memory LC | wyłączone (brak `RAG_API_URL`) |

## Sekrety (host_vars, nie Git)

- `openclaw_gateway_token` (istniejący)
- `librechat_jwt_secret`, `librechat_jwt_refresh_secret`
- `librechat_creds_key`, `librechat_creds_iv`

## Smoke (2026-05-17)

- `http://127.0.0.1:3080/` → 200
- `https://t630.colobus-micro.ts.net/chat/` → 200 (było 502 przed deploy)
- Kontenery: `librechat`, `librechat-mongo` Up

## Pliki

| Repo | Ścieżka |
|------|---------|
| homeserver-services | `roles/librechat/` |
| homeserver-services | `playbooks/t630.yml` (tag `librechat`) |
| homeserver-services | `inventory/group_vars/t630_servers.yml` |

## Deploy

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags librechat
```

## Następne

- Pierwsze logowanie / rejestracja w UI → potem `ALLOW_REGISTRATION=false`
- Smoke wiadomość do `openclaw/default` w przeglądarce
- SPEC-007E — tool policies, runbook final, contracts
