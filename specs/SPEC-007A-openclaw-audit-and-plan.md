# SPEC-007A: Audyt OpenClaw + plan rozwoju (post OCP-1 archive)

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: done
Repo: workspace (+ read-only: homeserver-services, openclaw-control-plane, life-platform)
Owner: karolkurek
Risk: low (audyt read-only); medium jeśli smoke wymaga restartu gateway
Type: ops / architecture
Zablokowany przez: —
Blokuje: [SPEC-007B](SPEC-007B-openclaw-caddy-ingress.md) *(planowany)*, [SPEC-007C](SPEC-007C-librechat-compose.md) *(planowany)*

## Cel

1. **Read-only audyt** obecnej instalacji OpenClaw na T630 oraz relacji z `openclaw-control-plane` i zarchiwizowanym EPIC-OCP-1.
2. **Udokumentowany plan** podziału repo, workflow zmian i ścieżki do LibreChat/LobeChat (bez reinstall OpenClaw).
3. **Smoke** `/v1/models` i `/v1/chat/completions` (loopback + tailnet przez Caddy) — stan wyjściowy przed 007B/C.
4. **Inwentaryzacja runtime OCP** na T630 (kontenery, porty, DB) — rekomendacja wyłączenia w 007E, nie w tym SPEC bez osobnego approval.

## Kontekst

- **EPIC-OCP-1 zarchiwizowany** (2026-05-17): `apps/ui` + `apps/api` w `openclaw-control-plane` — bez dalszego rozwoju.
- **Delegacja UI:** LibreChat (007C) + opcjonalnie LobeChat (007D).
- **SoT config:** `openclaw-control-plane` (`agents/`, `policies/`, `config/`) → `scripts/stage-config.py` → review → Ansible `homeserver-services/roles/openclaw`.
- **Runtime:** `~/.openclaw` na T630, systemd `openclaw-gateway` (:18789 loopback).
- ADR OCP: `openclaw-control-plane/docs/adr/2026-05-17-archive-epic-ocp-1-librechat-delegation-ui.md`.

## Decyzje (utrwalone w tym SPEC)

| Temat | Decyzja |
|-------|---------|
| Reinstall OpenClaw | **Nie** w EPIC-007 |
| Nowe repo | **Nie** — `openclaw-control-plane` + `homeserver-services` |
| UI delegacji | **LibreChat** (nie OCP `apps/ui`) |
| `openclaw-control-plane/apps/` | Zamrożone — tylko referencja |
| Wyłączenie OCP stack (Postgres/UI) | Propozycja w raporcie audytu; wykonanie → **007E** + `APPROVE_DEPLOY` |

## Zakres

### In scope

1. Checklist audytu T630 (poniżej) — wykonanie na hoście lub przez SSH; wyniki w worklogu.
2. Porównanie: `openclaw-config.json.j2` (Ansible) vs `~/.openclaw/openclaw.json` (runtime drift).
3. Porównanie: `openclaw-control-plane` `build/openclaw/` (po `stage-config.py --validate-only`) vs runtime — czy pipeline jest aktualny.
4. Smoke `/v1` (z tokenem z vault/host_vars — **nie** w logach worklogu).
5. Dokument **plan rozwoju**: `docs/plans/openclaw-007-development-plan.md` (w workspace).
6. Worklog: `docs/worklog/EPIC-007/SPEC-007A-2026-05-17-openclaw-audit.md`.
7. Aktualizacja EPIC-007 child table — status 007A po domknięciu.

### Out of scope

- Deploy LibreChat, zmiany Caddy → **007B**, **007C**.
- Zmiany `openclaw_agent_tool_policies` → **007E**.
- `docker compose down` stacku OCP bez approval.
- Commit sekretów / tokenów.

## Checklist audytu T630 (read-only)

Wykonać jako użytkownik runtime (np. `t630`). Wyniki: tabela w worklogu (OK / FAIL / N/A + jedna linia komentarza).

### A. Gateway systemd

```bash
systemctl is-active openclaw-gateway
systemctl show openclaw-gateway -p ActiveState,SubState,MainPID
/usr/bin/openclaw --version 2>/dev/null || openclaw --version
ss -lntp | grep 18789
curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/  # oczekiwane: 2xx/3xx/401, nie connection refused
```

### B. Konfiguracja runtime

```bash
test -f ~/.openclaw/openclaw.json && jq '.gateway.port, .gateway.http.endpoints.chatCompletions.enabled, .gateway.auth != null' ~/.openclaw/openclaw.json
openclaw doctor 2>&1 | tail -30   # jeśli dostępne
```

Nie wklejać całego `openclaw.json` do worklogu (może zawierać odniesienia do sekretów).

### C. Agenci i polityki (skrót)

```bash
jq '.agents.list | length' ~/.openclaw/openclaw.json 2>/dev/null
jq '.agents.list[].id' ~/.openclaw/openclaw.json 2>/dev/null | head -20
ls -la ~/.openclaw/workspace/ 2>/dev/null | head -10
```

### D. Caddy / tailnet (z maszyny w tailnecie)

```bash
curl -sS -o /dev/null -w "%{http_code}" https://t630.colobus-micro.ts.net/openclaw/
# /v1 wymaga Bearer — patrz sekcja Smoke
```

### E. EPIC-OCP-1 runtime (inwentaryzacja)

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -iE 'openclaw|ocp|librechat|control' || true
ss -lntp | grep -E '3000|3001|3080|5432|6379' || true
```

Zanotować: czy działają kontenery OCP UI/API, Postgres, Redis; które porty zajęte.

### F. Ansible / inventory (lokalnie, bez sekretów)

```bash
cd ~/repos/homeserver-services
grep -E 'openclaw_enabled|openclaw_gateway_token|openclaw_coding_agent' inventory/group_vars/t630_servers.yml inventory/host_vars/t630.yml 2>/dev/null | sed 's/:.*//' || true
# Tylko nazwy kluczy — nie wartości z host_vars
ansible-playbook playbooks/t630.yml --syntax-check
```

### G. openclaw-control-plane (lokalnie)

```bash
cd ~/repos/openclaw-control-plane
python3 scripts/validate-policies.py
python3 scripts/stage-config.py --validate-only
# Opcjonalnie: diff stat build/openclaw vs last deploy — bez sekretów w output
```

## Smoke `/v1` (wymagane przed zamknięciem 007A)

Token: z Infisical / `host_vars` — **nie** commitować, **nie** logować w worklogu.

```bash
export OPENCLAW_GATEWAY_TOKEN='…'   # lokalnie, nie w plikach repo

# Loopback (na T630)
curl -sS http://127.0.0.1:18789/v1/models \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" | jq '.data[0].id'

curl -sS http://127.0.0.1:18789/v1/chat/completions \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"openclaw/default","messages":[{"role":"user","content":"SPEC-007A smoke ping"}]}' \
  | jq '.choices[0].message.content // .error'

# Tailnet (z laptopa)
curl -sS https://t630.colobus-micro.ts.net/v1/models \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" | jq '.data | length'
```

| Test | Oczekiwanie |
|------|-------------|
| `/v1/models` loopback | HTTP 200, lista zawiera `openclaw/*` |
| `/v1/chat/completions` loopback | HTTP 200 lub kontrolowany błąd policy (nie 502) |
| `/v1/models` tailnet | Jak loopback (Caddy proxy OK) |
| Bez Bearer na tailnet | 401/403 (nie 200 z pełną listą) |

Jeśli auth wyłączone — **FAIL** 007A; naprawa tokena w osobnym deploy (approval) przed 007B.

## Deliverable: plan rozwoju

Utworzyć w workspace: [`docs/plans/openclaw-007-development-plan.md`](../docs/plans/openclaw-007-development-plan.md)

Minimalna treść:

1. **Podział repo** (tabela z EPIC-007).
2. **Workflow zmian** (kroki: OCP edit → validate → stage → Ansible → smoke).
3. **Mapowanie UI:** LibreChat vs zamrożone OCP `apps/`.
4. **Lista agentów** widocznych w LibreChat MVP (`openclaw/default` + ewent. whitelist).
5. **Rekomendacja OCP runtime:** keep / stop / remove (z uzasadnieniem z audytu F).
6. **Kolejność SPECs** 007B→007E.

## Definition of Done

- [x] Checklist A–G wykonany; wyniki w worklogu (bez sekretów).
- [x] Smoke `/v1` loopback + tailnet — PASS.
- [x] `docs/plans/openclaw-007-development-plan.md` istnieje i uzupełniony po audycie.
- [x] Worklog SPEC-007A w `docs/worklog/EPIC-007/`.
- [x] Brak zmian deployowych w tym SPEC.

## Rollback

Nie dotyczy — audyt read-only. Smoke nie modyfikuje stanu.

## Approval gates

| Akcja | Approval |
|-------|----------|
| Audyt + worklog + plan | karolkurek (review dokumentu) |
| Restart gateway / Ansible apply | **Nie** w 007A — osobny task jeśli smoke FAIL |

## Ryzyka

| Ryzyko | Mitigacja |
|--------|-----------|
| Wyciek tokena w worklog | Tylko „token ustawiony: tak/nie”; bez wartości |
| Mylenie OCP UI z LibreChat | Plan rozwoju + ADR już w OCP |
| Drift config niezauważony | Porównanie jq kluczy gateway, nie pełny diff z sekretami |

## Powiązane

- [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
- `openclaw-control-plane/docs/adr/2026-05-17-archive-epic-ocp-1-librechat-delegation-ui.md`
- `homeserver-services/docs/runbooks/openclaw-project-workflow.md`
