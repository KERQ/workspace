# Runbook: OpenClaw Gateway + LibreChat (T630)

**EPIC:** [EPIC-007](../specs/epics/EPIC-007-openclaw-gateway-librechat.md)  
**Status:** done (007A–007E, 2026-05-17)

## Działające URL-e (tailnet)

| Usługa | URL | Uwagi |
|--------|-----|-------|
| **LibreChat** (kanoniczny UI delegacji) | `https://t630.colobus-micro.ts.net/chat/` | Zawsze ze **slash** na końcu (lub przekierowanie z `/chat`) |
| OpenClaw Gateway UI | `https://t630.colobus-micro.ts.net/openclaw/` | Control UI gatewaya |
| OpenClaw API `/v1` | `https://t630.colobus-micro.ts.net/v1/...` | Bearer `OPENCLAW_GATEWAY_TOKEN` |
| ClawSuite (POC) | `https://t630.colobus-micro.ts.net/clawsuite/` | **Nie** używać `:3002` bez Caddy |
| Forgejo | `https://t630.colobus-micro.ts.net/git/` | |
| OpenClaw Studio | `http://127.0.0.1:3000/` | Tylko loopback na T630 |

## Czego nie używać

- `https://…/chat` **bez** końcowego `/` — historycznie pusty ekran (naprawione: Caddy `redir /chat /chat/ permanent`).
- `http://192.168.1.20:3000/` — Studio tylko na `127.0.0.1`.
- `http://<tailscale-ip>:3002/` — ClawSuite bez Caddy → „Initializing…”.
- Wbudowana zakładka **Agents** w LibreChat — błąd `agent_id is required` (to API LibreChat, nie OpenClaw).

## Architektura (skrót)

```text
Przeglądarka (tailnet)
  → Caddy :80 (/chat/ → 127.0.0.1:3080)
  → LibreChat (network_mode: host, 127.0.0.1:3080)
  → OpenClaw Gateway (127.0.0.1:18789/v1, Bearer token)
  → LiteLLM / agenci (G2, polityki w openclaw.json)
```

Gateway nasłuchuje **tylko na loopback** — LibreChat musi być w `network_mode: host` (nie `host.docker.internal`).

## Smoke `/v1`

```bash
export OPENCLAW_GATEWAY_TOKEN='…'   # vault / host_vars — nie logować

curl -sS https://t630.colobus-micro.ts.net/v1/models \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" | jq .

curl -sS https://t630.colobus-micro.ts.net/v1/chat/completions \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"openclaw/default","messages":[{"role":"user","content":"ping"}]}' | jq .
```

Z T630 (loopback):

```bash
curl -sS http://127.0.0.1:18789/health
docker exec librechat wget -qO- http://127.0.0.1:18789/health
```

## Deploy

### Caddy (life-platform)

```bash
cd life-platform/domains/home/ansible
ansible-playbook playbooks/t630.yml -l t630 --tags caddy,disruptive
```

Ważne w `Caddyfile`: `redir /chat /chat/ permanent` (nie `handle /chat { redir }` — nie działało).

### LibreChat (homeserver-services)

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags librechat
```

Sekrety w `inventory/host_vars/t630.yml` (gitignored): `openclaw_gateway_token`, `librechat_jwt_*`, `librechat_creds_*`.

### OpenClaw gateway (po zmianie config)

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags openclaw
sudo systemctl restart openclaw-gateway
```

## LibreChat — pierwsze użycie

1. URL: `https://t630.colobus-micro.ts.net/chat/`
2. Zaloguj się (rejestracja włączona na tailnecie — po utworzeniu konta rozważ `ALLOW_REGISTRATION=false`).
3. **Model (agent):** wybierz z listy (SPEC-007F):
   - **OpenClaw** → `openclaw/default` (orchestrator, domyślny)
   - **Research** → `openclaw/research_agent`
   - **Personal** → `openclaw/personal_agent`
   - **Finance** → `openclaw/finance_agent`
   - **Smart Home** → `openclaw/smart_home_agent`
4. Wyślij krótki prompt.

**Nie ma w UI:** `coding_agent`, `infra_agent`, `ha_config_agent` (deploy / `group:fs` / `group:runtime`).

## Troubleshooting

| Objaw | Przyczyna | Działanie |
|-------|-----------|-----------|
| Biały ekran | URL `/chat` bez `/` lub stary cache | Użyj `/chat/`; Cmd+Shift+R; wyczyść site data |
| `agent_id is required` | Zakładka Agents w LC | Nowy chat → endpoint **OpenClaw**, nie Agents |
| `Request timed out` | LC nie docierał do gatewaya (bridge → 127.0.0.1) | Sprawdź `docker inspect librechat` → `network=host`; `docker exec librechat wget -qO- http://127.0.0.1:18789/health` |
| 502 na `/chat/` | LibreChat down | `docker ps \| grep librechat`; redeploy tag `librechat` |
| 401 na `/v1` | Zły/brak tokena | Zsynchronizuj `OPENCLAW_GATEWAY_TOKEN` w LC `.env` i `openclaw.json` |

Logi:

```bash
docker logs librechat --tail 50
journalctl -u openclaw-gateway -n 50 --no-pager
```

## Polityki narzędzi (delegacja UI)

- UI LibreChat → allowlist **`librechat_openclaw_models`** (007F): orchestrator, research, personal, finance, smart home.
- Bez `ops_deploy`, `group:fs`, `group:runtime` dla agentów w UI.
- `coding_agent` / `infra_agent` / `ha_config_agent` / `main` — **poza** selektorem (audyt w SPEC-007F).
- Konfiguracja: `homeserver-services/roles/librechat/defaults/main.yml`, polityki narzędzi: `roles/openclaw/defaults/main.yml`.

## OCP runtime (zarchiwizowany EPIC-OCP-1)

Stack Postgres/Redis w `/opt/openclaw-control-plane/runtime` — **zatrzymany** w 007E (brak konsumenta UI/API).

Wznowienie (tylko jeśli potrzebne):

```bash
ssh t630 'cd /opt/openclaw-control-plane/runtime && docker compose start'
```

Zatrzymanie:

```bash
ssh t630 'cd /opt/openclaw-control-plane/runtime && docker compose stop'
```

## Kolejność restartu

1. `openclaw-gateway` (systemd)
2. LibreChat (`docker compose` w `/opt/homeserver-services/t630-config/librechat/`)
3. Caddy (jeśli zmiana ingress)
