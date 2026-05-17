# SPEC-007B: T630 — Caddy ingress `/v1` (audyt) + `/chat/` pod LibreChat

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: done
Repo: life-platform, workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-007A](SPEC-007A-openclaw-audit-and-plan.md) **done**
Blokuje: [SPEC-007C](SPEC-007C-librechat-compose.md) *(planowany)*

## Cel

1. **Potwierdzić** działający ingress OpenClaw **`/v1*`** i **`/openclaw*`** przez Caddy + Tailscale Serve (wynik z 007A → utrwalony w smoke).
2. Dodać reverse proxy **`https://t630.colobus-micro.ts.net/chat/`** → **`127.0.0.1:3080`** (LibreChat — backend w **007C**).
3. Udokumentować **działające URL-e** UI (ClawSuite, OpenClaw, przyszły LibreChat) — uniknąć bezpośredniego `:3002` bez Caddy.

## Kontekst

- Jeden Caddy Docker na T630 ([SPEC-016](SPEC-016-t630-caddy-unify-docker.md)); Tailscale Serve → `http://127.0.0.1:80`.
- [SPEC-007A](SPEC-007A-openclaw-audit-and-plan.md): `/v1` smoke **PASS** (401 bez Bearer); port **3080 wolny**.
- ClawSuite: **nie** wchodzić na `http://<tailscale-ip>:3002/` — API wymaga Caddy (`/api/*` shim). Działający URL: `https://t630.colobus-micro.ts.net/clawsuite/`.
- OpenClaw Studio `:3000` — tylko **loopback** (`127.0.0.1`); z LAN odrzuca połączenie — użyć `/openclaw/` lub tunel SSH.
- LibreChat subdirectory: `DOMAIN_CLIENT` / `DOMAIN_SERVER` z pełnym URL zawierającym `/chat` — konfiguracja w **007C**, nie w tym SPEC.

## Decyzje

| Temat | Wartość | Uwagi |
|-------|---------|-------|
| Właściciel Caddyfile | `life-platform/domains/home/configs/caddy/Caddyfile` | |
| Publiczny URL LibreChat | `https://t630.colobus-micro.ts.net/chat/` | Wzorzec jak Forgejo `/git/` |
| Upstream LibreChat | `127.0.0.1:3080` | Kontener/compose w 007C |
| Caddy routing | `handle /chat` → 308; `handle_path /chat/*` → :3080 | `handle_path` stripuje prefiks dla upstreamu |
| `/v1*`, `/openclaw*` | **Bez zmian** | Audyt tylko — już działają |
| Opcjonalny vhost | `http://chat.t630.colobus-micro.ts.net` | Jak Forgejo `git.t630.*` — na przyszły DNS; **nie blokuje** MVP |
| Auth UI `/chat` | Tailscale + LibreChat login (007C) | Brak Basic Auth w Caddy w MVP |
| Deploy Caddy | `life-platform` playbook, tag `caddy` | `APPROVE_DEPLOY=yes` |

## Zakres

### In scope

1. **Audyt** (smoke) istniejących tras `/v1*`, `/openclaw*` — tabela w worklogu.
2. Bloki Caddy `/chat` + `/chat/*` (przed deploy LibreChat może zwracać **502** — akceptowalne).
3. Komentarz w Caddyfile: ClawSuite wymaga HTTPS przez hosta (nie raw `:3002`).
4. Worklog + aktualizacja [openclaw-007-development-plan.md](../docs/plans/openclaw-007-development-plan.md) (sekcja URL-e).
5. Szkic runbooku: `docs/runbooks/t630-openclaw-gateway-librechat.md` (sekcja ingress).

### Out of scope

- Compose LibreChat, `librechat.yaml`, env `DOMAIN_*` → **007C**.
- Zmiana bind OpenClaw Studio `:3000` (pozostaje loopback).
- Wyłączenie ClawSuite / OCP → **007E**.
- Basic Auth na `/chat` w Caddy (opcjonalnie później).

## Pliki

| Repo | Plik |
|------|------|
| life-platform | `domains/home/configs/caddy/Caddyfile` |
| workspace | ten SPEC, worklog, runbook (sekcja ingress) |

## Zmiany Caddyfile (docelowe)

Po bloku `/git/*`, przed `/zigbee2mqtt`:

```caddyfile
  # LibreChat (SPEC-007B) — https://t630.colobus-micro.ts.net/chat/
  handle /chat {
    redir /chat/ 308
  }
  handle_path /chat/* {
    reverse_proxy 127.0.0.1:3080 {
      transport http {
        read_timeout 0
        write_timeout 0
      }
    }
  }
```

Opcjonalnie (icebox DNS), poza blokiem `:80`:

```caddyfile
http://chat.t630.colobus-micro.ts.net {
  reverse_proxy 127.0.0.1:3080 {
    transport http {
      read_timeout 0
      write_timeout 0
    }
  }
}
```

## Smoke

### Faza A — przed deploy Caddy (lokalnie)

```bash
# Walidacja składni (w kontenerze lub caddy validate jeśli dostępne)
docker run --rm -v "$(pwd)/domains/home/configs/caddy:/etc/caddy:ro" \
  caddy:2.8.4-alpine caddy validate --config /etc/caddy/Caddyfile
```

### Faza B — audyt `/v1` (bez zmiany Caddy — powtórzenie 007A)

```bash
# Z tailnetu — token lokalnie, nie w logach
curl -sS -o /dev/null -w "v1_models=%{http_code}\n" \
  https://t630.colobus-micro.ts.net/v1/models \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN"

curl -sS -o /dev/null -w "v1_no_auth=%{http_code}\n" \
  https://t630.colobus-micro.ts.net/v1/models
# Oczekiwane: 200 z tokenem, 401 bez
```

### Faza C — po deploy Caddy (route `/chat`)

```bash
# Na T630 — Caddy → LibreChat (502 OK jeśli LibreChat jeszcze nie działa)
curl -sS -o /dev/null -w "%{http_code}\n" \
  -H "Host: t630.colobus-micro.ts.net" http://127.0.0.1/chat/

# Z tailnetu
curl -k -sS -o /dev/null -w "%{http_code}\n" \
  https://t630.colobus-micro.ts.net/chat/
# Oczekiwane przed 007C: 502; po 007C: 200
```

### Faza D — regresja ClawSuite / Forgejo

```bash
curl -k -sS -o /dev/null -w "git=%{http_code}\n" https://t630.colobus-micro.ts.net/git/
curl -k -sS -o /dev/null -w "clawsuite=%{http_code}\n" https://t630.colobus-micro.ts.net/clawsuite/
curl -k -sS -o /dev/null -w "openclaw=%{http_code}\n" https://t630.colobus-micro.ts.net/openclaw/
```

## Deploy

```bash
# life-platform — z katalogu domeny home (patrz istniejący runbook HA/Caddy)
# Wymaga: APPROVE_DEPLOY=yes
ansible-playbook domains/home/ansible/... -l t630 --tags caddy
# lub docker compose up -d --force-recreate caddy w domains/home/configs/
```

## Rollback

1. Usuń bloki `/chat` z Caddyfile.
2. `docker compose up -d --force-recreate caddy` w `domains/home/configs/`.

## Definition of Done

- [x] Caddyfile z `/chat/` w repo `life-platform`.
- [x] Caddy zredeployowany na T630 (`APPROVE_DEPLOY=yes`, 2026-05-17).
- [x] Smoke `/v1` — PASS (jak 007A).
- [x] `curl https://t630.../chat/` — **502** (OK przed 007C).
- [x] Regresja `/git/`, `/clawsuite/`, `/openclaw/` — bez regresji.
- [x] Worklog SPEC-007B + runbook sekcja URL-e.
- [x] EPIC-007 child SPEC-007B → `done`.

## Następne

- [SPEC-007C](SPEC-007C-librechat-compose.md) — LibreChat na `:3080`, `DOMAIN_CLIENT=https://t630.colobus-micro.ts.net/chat`, custom endpoint OpenClaw `/v1`.
