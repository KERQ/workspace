# SPEC-007F: LibreChat — wybór agentów OpenClaw (bezpieczny allowlist)

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: planned
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: config + docs
Zablokowany przez: [SPEC-007E](SPEC-007E-openclaw-tool-policies-contracts.md) **done**

## Problem

LibreChat ma `modelSelect: true`, ale `modelSpecs.enforce` i jedna pozycja `openclaw/default` — użytkownik nie może wybrać agenta (research, personal, smart home itd.), mimo że gateway `/v1/models` zwraca `openclaw/<agent_id>`.

## Cel

Eksponować w LibreChat **wiele presetów** (dropdown), każdy mapowany na `openclaw/<agent_id>`, z **twardym allowlistem** agentów bez `ops_deploy`, `group:fs`, `group:runtime` w polityce narzędzi.

Po SPEC:

- W UI `/chat/` widać np. „OpenClaw (Orchestrator)”, „Research”, „Personal”, „Finance”, „Smart Home”.
- Domyślny preset nadal **orchestrator** (`openclaw/default`).
- Agentów z uprawnieniami deploy/fs/runtime **nie ma** na liście.

## Audyt agentów (allowlist)

Na podstawie `openclaw_agent_tool_policies` w `roles/openclaw/defaults/main.yml`:

| Model LibreChat | Agent | `ops_deploy` | `group:fs` | `group:runtime` | W allowlist 007F |
|-----------------|-------|--------------|------------|-----------------|------------------|
| `openclaw/default` | orchestrator | — | — | — | **tak** (default) |
| `openclaw/research_agent` | research_agent | — | deny | deny | **tak** |
| `openclaw/personal_agent` | personal_agent | — | deny | deny | **tak** |
| `openclaw/finance_agent` | finance_agent | — | deny | deny | **tak** |
| `openclaw/smart_home_agent` | smart_home_agent | — | deny | deny | **tak** |
| `openclaw/coding_agent` | coding_agent | allow | allow | allow | **nie** |
| `openclaw/infra_agent` | infra_agent | allow | allow | allow | **nie** |
| `openclaw/ha_config_agent` | ha_config_agent | — | allow | — | **nie** |
| `openclaw/main` | main | — | allow | allow | **nie** |
| `openclaw/orchestrator` | orchestrator | — | — | — | **nie** (duplikat `default`) |

**Uwaga:** wybór agenta w LC zmienia **model** w żądaniu `/v1`, nie provider LLM (Codex/Gemini/CLI zostaje wg overrides agenta w OpenClaw).

## Implementacja (Ansible)

### 1. `roles/librechat/defaults/main.yml`

```yaml
librechat_openclaw_models:
  - id: "openclaw/default"
    label: "OpenClaw"
    description: "Orchestrator — routing, Plane, bez deploy/fs"
    default: true
  - id: "openclaw/research_agent"
    label: "Research"
    description: "Badania, web search, bez fs/runtime"
  - id: "openclaw/personal_agent"
    label: "Personal"
    description: "Kalendarz, Obsidian, bez fs/runtime"
  - id: "openclaw/finance_agent"
    label: "Finance"
    description: "Rynek, bez fs/runtime"
  - id: "openclaw/smart_home_agent"
    label: "Smart Home"
    description: "Home Assistant API"
```

Opcjonalnie: `librechat_openclaw_models_extra` w `host_vars` (pusta domyślnie) — bez dodawania `coding_agent` bez osobnego SPEC + audytu.

### 2. `roles/librechat/templates/librechat.yaml.j2`

- `modelSpecs.list` — pętla Jinja po `librechat_openclaw_models` (preset: endpoint OpenClaw + `model: item.id`).
- `endpoints.custom[0].models.default` — lista samych `id` z allowlisty.
- Zachować: `interface.agents: false`, `enforce: true`, `ENDPOINTS=custom`.

### 3. Dokumentacja

- Aktualizacja [t630-openclaw-gateway-librechat.md](../docs/runbooks/t630-openclaw-gateway-librechat.md) — sekcja „Wybór agenta”.
- Worklog: `docs/worklog/EPIC-007/SPEC-007F-*.md`.

## Poza zakresem

- Wybór **konkretnego LLM** (Codex vs LiteLLM) z LibreChat — to nadal OpenClaw per agent.
- `coding_agent`, `infra_agent`, `ha_config_agent`, `main` w UI.
- LobeChat (007D).
- Zmiana `openclaw_agent_model_overrides`.

## Guardrails

```text
- allowlist w Ansible — nie „fetch all z /v1/models”
- każdy nowy agent w LC wymaga audytu tool policy (jak tabela wyżej)
- no ops_deploy / group:fs / group:runtime z UI
```

## Test plan (smoke)

1. Deploy: `APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags librechat`
2. UI: `/chat/` — dropdown pokazuje 5 presetów; default = OpenClaw.
3. Wyślij krótki prompt na **Research** i **Personal** — odpowiedź bez błędu 401/502.
4. Negatywny: w `librechat.yaml` nie ma `openclaw/coding_agent` (grep po deploy).
5. Regresja: `openclaw/default` nadal działa jak przed 007F.

```bash
# API (opcjonalnie)
curl -sS -H "Authorization: Bearer $TOKEN" \
  https://t630.colobus-micro.ts.net/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"openclaw/research_agent","messages":[{"role":"user","content":"Powiedz: OK"}]}'
```

## Definition of Done

- [ ] Allowlist w `defaults/main.yml` + szablon `librechat.yaml.j2`
- [ ] Wdrożone na T630, smoke UI + jeden agent nie-default
- [ ] Runbook zaktualizowany
- [ ] EPIC-007 child table + BACKLOG
