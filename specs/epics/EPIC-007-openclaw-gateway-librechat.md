# EPIC-007: OpenClaw Gateway `/v1` + LibreChat/LobeChat (delegation UI)

Status: done
Owner: karolkurek
Risk: high
Repos: homeserver-services, life-platform, workspace (docs/contracts/runbooks)
Blokuje: EPIC-009 (Forgejo bot — woła `/v1`), EPIC-010 (approval-first PR flow)
Zablokowany przez: [EPIC-006](EPIC-006-forgejo-mvp.md) **done** (Forgejo SoR), [SPEC-016](../SPEC-016-t630-caddy-unify-docker.md) **done** (jeden Caddy na T630)

## Cel

Udostępnić **OpenClaw Gateway** na T630 jako **OpenAI-compatible HTTP API** (`/v1/models`, `/v1/chat/completions`) wyłącznie przez **tailnet + auth**, oraz podłączyć **LibreChat** (MVP) lub **LobeChat** (opcjonalnie) jako cienki UI delegowania do agenta `openclaw/default`.

Po zakończeniu epiku:

- Z maszyny w tailnecie działa smoke: `GET /v1/models` i `POST /v1/chat/completions` z tokenem gatewaya.
- **LibreChat** na T630 (`:3080`) jest **kanonicznym UI delegacji** (chat → `openclaw/default`); opcjonalnie LobeChat (007D).
- **OpenClaw memory** pozostaje jedynym źródłem pamięci agentów (`~/.openclaw/workspace/`).
- Polityki narzędzi dla ścieżki delegacji UI **nie** obejmują: sekretów, deployu, merge, protected push.
- Kontrakt `openclaw_gateway` i `librechat` w `contracts/services/ports.yml` — `status: active` + runbook.

## Decyzja strategiczna: EPIC-OCP-1 zarchiwizowany

**EPIC-OCP-1** (*OpenClaw Personal Control Plane* — `openclaw-control-plane/apps/{ui,api}`) jest **archiwizowany** (2026-05-17). Nie kontynuujemy Stories OCP-06/07 ani rozwoju własnego dashboardu Next/Nest.

| Było (OCP-1) | Jest (EPIC-007) |
|--------------|-----------------|
| `apps/ui` — chat, sessions, tasks, approvals | **LibreChat** (+ opcj. LobeChat) |
| `apps/api` — approvals, costs, memory API | OpenClaw Gateway `/v1` + polityki w runtime |
| Osobny Postgres/Redis pod OCP | Do audytu / ewent. wyłączenia (007A) |

**Repo `openclaw-control-plane` zostaje** (nie nowe repo): `agents/`, `policies/`, `projects/`, `config/`, `scripts/stage-config.py` → render do `~/.openclaw`. **`apps/` zamrożone** — tylko referencja.

ADR (OCP): `openclaw-control-plane/docs/adr/2026-05-17-archive-epic-ocp-1-librechat-delegation-ui.md`

## Kontekst

- [`BACKLOG.md`](../../BACKLOG.md) — sekcja **Now**, EPIC-007.
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md) — §2.1 Gateway `/v1`, §5 porty, §10 LibreChat, §18 Etap 2, must-have MVP.
- [`docs/ideas/ai_native_workspace_plan.md`](../../docs/ideas/ai_native_workspace_plan.md) — OpenClaw jako policy/memory/execution layer.
- [`contracts/services/ports.yml`](../../contracts/services/ports.yml) — `openclaw_gateway` (18789), `librechat` (3080, planned).

### Stan wyjściowy (T630, 2026-05-17)

| Element | Stan | Uwagi |
|---------|------|--------|
| `openclaw-gateway` (systemd) | działa na hoście | Rola `homeserver-services/roles/openclaw` |
| Port `18789` | loopback | `gateway.port` w `openclaw-config.json.j2` |
| `chatCompletions` HTTP | **włączone** w szablonie | `gateway.http.endpoints.chatCompletions.enabled: true` |
| Caddy `/v1*` → `127.0.0.1:18789` | **jest** | `life-platform/.../Caddyfile` (po Tailscale Serve → Caddy :80) |
| Caddy `/openclaw*` | **jest** | Control UI przez ten sam host |
| LibreChat compose | **brak** | Do wdrożenia w 007C — **zastępuje OCP UI** |
| OCP `apps/ui` + `apps/api` | zamrożone | EPIC-OCP-1 archived; kod w repo bez rozwoju |
| `openclaw_enabled` w Ansible | domyślnie `false` | Włączenie przez inventory / `-e` przy deploy |
| Forgejo / Git flow | **done** | EPIC-006 — nie w scope 007 |

> EPIC-007 to **utrwalenie** ścieżki `/v1` + **LibreChat jako UI delegacji**, nie greenfield gateway ani kontynuacja OCP-1.

## Podział repozytoriów (utrwalony)

| Co | Gdzie |
|----|--------|
| Agenci, polityki, projekty, render pipeline | `openclaw-control-plane` |
| Runtime: systemd gateway, compose LibreChat, Ansible | `homeserver-services` |
| Caddy ingress (tailnet) | `life-platform` |
| Plany, runbooki, kontrakty | `workspace` |
| **Nie** tworzymy | nowego repo „openclaw-gateway” |

## Decyzje wstępne (do potwierdzenia w SPEC-007A)

| Temat | Propozycja MVP | Uwagi |
|-------|----------------|-------|
| Host gateway | T630 | Zgodnie z architekturą; LiteLLM na G2 (`:4000`) bez zmian |
| Port gateway | `18789` loopback | Bez publicznego bindu poza localhost |
| Ekspozycja zewnętrzna | Tailscale → Caddy `:80` | Ścieżki `/v1/*`, `/openclaw/*`; bez bezpośredniego Serve na 18789 |
| Auth API `/v1` | Bearer `OPENCLAW_GATEWAY_TOKEN` | Token operatora; poza Git (host_vars / Infisical) |
| Auth LibreChat UI | Tailscale + Caddy (session/basic) | Osobne sekrety JWT LibreChat — poza Git |
| UI delegacji | **LibreChat** pierwszy | LobeChat jako 007D (opcjonalny), nie blokuje MVP |
| Model w requestach | `openclaw/default` (i ewent. `openclaw/<agentId>`) | Nie surowy provider model |
| Memory | OpenClaw ON; LibreChat RAG/memory **OFF** | Brak duplikacji pamięci |
| MCP LibreChat | **out of scope** MVP | Etap 2 w dokumencie arch.; MVP = custom OpenAI `baseURL` |
| Deploy LibreChat | Docker Compose w `/srv/ai-stack/librechat/` | Rola Ansible `librechat` w homeserver-services |
| Loopback z kontenera LC → gateway | `host.docker.internal:18789` lub `172.17.0.1` | Do ustalenia w 007C (smoke w compose) |

## Repo impact matrix

| Repo | Impact | Uwagi |
|------|--------|-------|
| `homeserver-services` | write | OpenClaw gateway config/smoke; nowa rola `librechat`; playbook T630 |
| `life-platform` | write (Caddyfile) | Ingress `/chat/` lub vhost `chat.t630.*` → LibreChat `:3080` |
| `workspace` | write | Ten EPIC, child SPECs, runbook, `contracts/services/ports.yml` |
| `homeserver-core` | read | Backup ścieżek LibreChat — dopiero gdy volume powstanie (opcjonalnie w 007E) |
| `openclaw-control-plane` | read (+ ADR) | `agents/`, `policies/`, `config/` — SoT; **`apps/` bez rozwoju** |
| `investment-research` | none | Hard privacy — poza delegacją UI |

## In scope

- **Audyt** obecnej instalacji OpenClaw + drift vs `openclaw-control-plane` (007A); inwentaryzacja runtime OCP na T630 (compose/DB) pod ewent. wyłączenie.
- Weryfikacja i smoke **OpenAI-compatible** API na gatewayu (`/v1/models`, `/v1/chat/completions`).
- Wymuszenie auth token na produkcyjnej ścieżce tailnet (gdy brak — fail w SPEC, nie „open endpoint”).
- Audyt / doprecyzowanie Caddy dla `/v1` (timeouty WebSocket/streaming już są).
- **LibreChat** na T630: Compose + `librechat.yaml` z custom endpoint OpenClaw.
- Wyłączenie RAG i built-in memory po stronie LibreChat w konfiguracji.
- Ingress Caddy dla LibreChat (np. `https://t630.colobus-micro.ts.net/chat/` — wzorzec jak Forgejo `/git/`).
- Runbook: tokeny, smoke curl, troubleshooting, restart kolejności (gateway → LibreChat).
- Aktualizacja `contracts/services/ports.yml` (`openclaw_gateway.status`, `librechat.status`).
- Audyt `openclaw_agent_tool_policies` dla agentów dostępnych z UI — deny deploy/merge/secrets.

## Out of scope

- **EPIC-OCP-1** — dalszy rozwój `apps/ui`, `apps/api`, Stories OCP-06/07.
- Reinstall OpenClaw od zera / wipe `~/.openclaw` (osobny runbook DR).
- Forgejo bot, webhooks, `/openclaw review` → **EPIC-009**.
- Worktree, `difit`, `/srv/worktrees` → **EPIC-008**.
- Approval-first commit/push/PR → **EPIC-010**.
- GitHub mirror → **EPIC-011**.
- MCP servers w LibreChat → później (po stabilnym `/v1`).
- SwarmClaw, council, autoloop → icebox.
- Zmiana providerów LiteLLM / modeli agentów (osobne taski S5 OpenClaw).
- LobeChat — **SPEC-007D** opcjonalny; epik uznany za done bez 007D jeśli LibreChat wystarczy.

## Guardrails

```text
- no auto-deploy bez APPROVE_DEPLOY=yes
- no secrets w Git (OPENCLAW_GATEWAY_TOKEN, LIBRECHAT_JWT_*, .env)
- no public exposure poza tailnet
- no GitHub push mirror w tym epiku
- no agent merge / protected branch push / deploy z UI-delegacji
- no duplikacji memory w LibreChat/LobeChat
- investment-research: brak routingu ani agentów research w MVP UI
```

## Kolejność wdrożenia (child SPECs)

```text
007A (audyt OpenClaw + OCP runtime; plan repo/workflow; gateway /v1 smoke)
  → 007B (Caddy / tailnet ingress audit dla /v1 i /chat)
  → 007C (LibreChat compose + OpenClaw endpoint + UI smoke — zastępuje OCP UI)
  → 007D (LobeChat — opcjonalnie)
  → 007E (tool policies + wyłączenie OCP stack na T630 jeśli uzasadnione + runbook + contracts)
```

Każdy child SPEC: **test plan (smoke/check) przed apply**, zgodnie z `PROJEKT.md` §test-first.

## Global Definition of Done

- [ ] Wszystkie child SPECs w statusie `done` lub świadomie anulowane (007D może być `cancelled`)
- [ ] `curl` z tailnetu: `/v1/models` zwraca listę z `openclaw/*`
- [ ] `curl` z tailnetu: `/v1/chat/completions` z `model: openclaw/default` — odpowiedź 200 (lub kontrolowany błąd policy, nie 502 Caddy)
- [ ] LibreChat UI dostępne przez tailnet; wiadomość testowa trafia do OpenClaw i wraca
- [ ] LibreChat: RAG i memory plugin wyłączone w config
- [ ] Brak możliwości z UI-delegacji: odczyt sekretów z host_vars, `ansible-playbook` deploy, `git push` na protected, merge PR
- [ ] `contracts/services/ports.yml` — `openclaw_gateway.status: active`, `librechat.status: active`
- [ ] Runbook: `docs/runbooks/t630-openclaw-gateway-librechat.md`

## Global test plan

### Faza A — przed deploy (syntax / config)

1. `openclaw doctor` (na T630 lub w kontenerze dev) po zmianie `openclaw.json`.
2. `ansible-playbook --syntax-check` dla `playbooks/t630.yml` z tagami `openclaw`, `librechat`.
3. `docker compose config` dla stacku LibreChat.
4. Walidacja Caddyfile (jeśli check w pipeline).
5. Contract check: porty zgodne z `contracts/services/ports.yml`.

### Faza B — po deploy gateway (smoke API)

```bash
# Z maszyny w tailnecie (token z vault/host_vars, nie w logach)
export OPENCLAW_GATEWAY_TOKEN='…'

# Loopback na T630
ssh t630 'curl -sS http://127.0.0.1:18789/v1/models \
  -H "Authorization: Bearer '"$OPENCLAW_GATEWAY_TOKEN"'" | jq .data[0].id'

# Przez Caddy / Tailscale Serve
curl -sS "https://t630.colobus-micro.ts.net/v1/models" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" | jq .

curl -sS "https://t630.colobus-micro.ts.net/v1/chat/completions" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"openclaw/default","messages":[{"role":"user","content":"ping EPIC-007 smoke"}]}' | jq .
```

### Faza C — po deploy LibreChat

1. Otwórz UI LibreChat w tailnecie (ścieżka z 007B).
2. Wybierz provider **OpenClaw**, model `openclaw/default`.
3. Wyślij krótki prompt; potwierdź odpowiedź i wpis w logach gatewaya.
4. Potwierdź w config LibreChat: brak włączonego RAG/memory store.

### Faza D — polityki (negative tests)

1. Prompt próbujący odczytać `/etc/passwd` lub `inventory/host_vars` — odrzucony lub bezpieczna odmowa (policy).
2. Prompt z prośbą o `git push origin main` / merge PR — brak wykonania (tool deny lub brak narzędzia).

## Rollback

| Poziom | Działanie |
|--------|-----------|
| Po 007A, przed LibreChat | Przywrócić poprzedni `openclaw.json`; `systemctl restart openclaw-gateway` |
| Po 007B | Usunąć blok Caddy `/chat`; reload Caddy |
| Po 007C | `docker compose down` LibreChat; gateway bez zmian |
| Awaria tokena | Rotacja `OPENCLAW_GATEWAY_TOKEN` w vault + restart gateway + update LibreChat env |

## Approval gates

| Gate | Wymagane approval |
|------|-------------------|
| Akceptacja szkicu EPIC-007 | karolkurek |
| SPEC-007A–E implementacja | per SPEC review |
| Deploy T630 (`openclaw`, `librechat`, Caddy reload) | **manual**, `APPROVE_DEPLOY=yes` |
| Ustawienie / rotacja tokenów gatewaya i LibreChat | karolkurek |
| Włączenie `openclaw_enabled: true` w inventory (jeśli jeszcze false) | karolkurek |

## Ryzyka

| Ryzyko | Mitigacja |
|--------|-----------|
| `/v1` bez auth na tailnecie | 007A wymaga tokena; test negatywny bez Bearer |
| Gateway token w logach LibreChat | `no_log` w Ansible; env tylko w `.env` na hoście |
| Duplikacja pamięci (LC RAG + OpenClaw) | Jawne OFF w `librechat.yaml`; review w 007C |
| Nadmierne uprawnienia agenta z UI | 007E audit `openclaw_agent_tool_policies` |
| Konflikt portów 3080 / 3000 | `ss -lntp` przed deploy; kontrakt portów |
| Timeouty długich completion | Caddy `read_timeout 0` (już na `/v1*`) |
| `openclaw_enabled: false` — config nie deployowany | Checklist w runbooku; explicit inventory flag |

## Child SPECs

| SPEC | Repo | Status | Opis |
|------|------|--------|------|
| [SPEC-007A](../SPEC-007A-openclaw-audit-and-plan.md) | workspace + homeserver-services | done | Audyt T630 2026-05-17; `/v1` PASS; plan rozwoju; OCP tylko PG/Redis |
| [SPEC-007B](../SPEC-007B-openclaw-caddy-ingress.md) | life-platform | done | Caddy `/chat/` → :3080 wdrożony; 502 do 007C; regresja OK |
| [SPEC-007C](../SPEC-007C-librechat-compose.md) | homeserver-services | done | LibreChat Compose + OpenClaw endpoint; `/chat/` 200 |
| SPEC-007D | homeserver-services | draft (optional) | LobeChat — ten sam endpoint OpenClaw; anulowalny |
| [SPEC-007E](../SPEC-007E-openclaw-tool-policies-contracts.md) | workspace + homeserver-services | done | Tool policies, runbook, OCP stop; tylko `openclaw/default` w LC |
| [SPEC-007F](../SPEC-007F-librechat-openclaw-agent-picker.md) | homeserver-services + workspace | done | LibreChat: wybór agentów (allowlist bez coding/infra) |
| SPEC-007D | homeserver-services | cancelled (optional) | LobeChat — nie wymagany po LibreChat MVP |

> Child SPECs utworzymy po akceptacji tego EPIC (kolejność: 007A → 007E).

## Powiązane epiki

| EPIC | Zależność od 007 |
|------|------------------|
| EPIC-008 worktree + difit | Nie blokuje; równoległy po stabilnym `/v1` |
| EPIC-009 Forgejo bot | Wymaga działającego `/v1` (bot woła completions) |
| EPIC-010 approval PR flow | Wymaga 007 + 008 + 009 |
| EPIC-011 GitHub mirror | Niezależny |
| EPIC-006 Forgejo | **done** — prerequisite |

## Źródła

- OpenClaw OpenAI HTTP API: https://docs.openclaw.ai/gateway/openai-http-api
- OpenClaw Memory: https://docs.openclaw.ai/concepts/memory
- LibreChat custom endpoints: https://www.librechat.ai/docs/configuration/librechat_yaml
- LibreChat MCP (poza MVP): https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/mcp_servers
