# SPEC-007H: LibreChat — pełna konfiguracja `coding_agent` + skills

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: done
Repo: homeserver-services, openclaw-control-plane, workspace
Owner: karolkurek
Risk: high
Type: infra + config + docs
Zablokowany przez: [SPEC-007F](SPEC-007F-librechat-openclaw-agent-picker.md) **done**
Blokuje: —

## Cel

Umożliwić wybór `coding_agent` bezpośrednio w LibreChat (`/chat/`) oraz zapewnić, że agent działa z kompletną i kontrolowaną konfiguracją narzędzi oraz repo skills, zgodną z politykami OpenClaw i zasadami approval.

## Kontekst

- [SPEC-007F](SPEC-007F-librechat-openclaw-agent-picker.md) celowo wykluczył `openclaw/coding_agent` z allowlisty LibreChat.
- Obecnie konfiguracja `coding_agent` istnieje po stronie OpenClaw (model + tools) w `homeserver-services`, ale nie jest eksponowana w UI LibreChat.
- Repo skills w kanonie projektu są utrzymywane w `homeserver-services/docs/skills/*/SKILL.md`; OpenClaw ma `nativeSkills: true`.
- `openclaw-control-plane` przechowuje scope deploy/import obejmujący `skills/` i `agents/` (round-trip runtime↔repo).

## Zakres

### In scope

- Dodanie `openclaw/coding_agent` do listy modeli LibreChat (dropdown) jako świadomie „uprzywilejowanego” presetu.
- Ujednolicenie opisu i etykiet modelu w LibreChat tak, aby użytkownik wiedział, że to tryb z uprawnieniami `fs/runtime/deploy`.
- Weryfikacja i doprecyzowanie polityki narzędzi `coding_agent` w OpenClaw (allow/deny + guardrails).
- Potwierdzenie ścieżki repo skills i ich dostępności dla sesji `coding_agent`.
- Smoke testy end-to-end: LibreChat → OpenClaw gateway → `coding_agent` → narzędzia (`git_status`, `docker_status`, `ai_dev`).
- Aktualizacja runbooków i kontraktów operacyjnych.

### Out of scope

- Dodawanie `infra_agent`/`ha_config_agent`/`main` do LibreChat.
- Redesign polityk modelowych (tiering kosztowy LiteLLM) poza potrzebami `coding_agent`.
- Automatyzacja deployu bez approval.

## Pliki / obszary

### Read

- `homeserver-services/roles/librechat/defaults/main.yml`
- `homeserver-services/roles/librechat/templates/librechat.yaml.j2`
- `homeserver-services/roles/openclaw/defaults/main.yml`
- `homeserver-services/roles/openclaw/templates/openclaw-config.json.j2`
- `homeserver-services/playbooks/tests/openclaw-coding-agent-smoke.yml`
- `homeserver-services/docs/runbooks/openclaw-project-workflow.md`
- `homeserver-services/docs/runbooks/agent-config-unification.md`
- `openclaw-control-plane/config/deploy-scope.yml`
- `openclaw-control-plane/config/import-scope.yml`
- `openclaw-control-plane/agents/coding_agent/*`

### Write

- `homeserver-services/roles/librechat/defaults/main.yml`
- `homeserver-services/roles/librechat/templates/librechat.yaml.j2` (tylko jeśli potrzebne zmiany walidacyjne)
- `homeserver-services/docs/runbooks/t630-openclaw-gateway-librechat.md`
- `homeserver-services/docs/runbooks/openclaw-project-workflow.md` (sekcja „LibreChat + coding_agent”)
- `openclaw-control-plane/agents/coding_agent/USER.md` (opcjonalnie: doprecyzowanie UX pod LibreChat)
- `workspace/specs/epics/EPIC-007-openclaw-gateway-librechat.md` (aktualizacja child table)

### Forbidden

- Sekrety (`host_vars`, `.env`, tokeny, klucze API).
- Bezpośrednia edycja `~/.openclaw/*` jako źródła prawdy.

## Do zrobienia

- [x] Dodać preset LibreChat `openclaw/coding_agent` do `librechat_openclaw_models` z jednoznaczną etykietą ryzyka (np. „Coding (FS/Runtime/Deploy)”).
- [x] Usunąć `openclaw/coding_agent` z `librechat_openclaw_models_forbidden`.
- [x] Zachować `modelSpecs.enforce: true` i statyczny allowlist (bez dynamicznego fetch z `/v1/models`).
- [x] Zweryfikować, że `openclaw_agent_tool_policies` dla `coding_agent` zawiera wymagane narzędzia developerskie (`git_status`, `docker_status`, `ai_dev`, `openclaw_tool_bridge`) i nie otwiera `group:messaging`.
- [x] Potwierdzić, że `openclaw_commands_native_skills: true` pozostaje aktywne.
- [x] Udokumentować mapę „repo skills -> runtime behavior” dla `coding_agent` (co jest kanonem i jak utrzymać spójność).
- [x] Zaktualizować runbook LibreChat o procedurę wyboru `coding_agent` i warning operacyjny.
- [x] Wykonać smoke testy API/UI i test negatywny dla agentów nadal zablokowanych.

## Definition of Ready

- [x] Cel i zakres są jasne
- [x] Repo i ryzyko określone
- [x] Test plan zdefiniowany
- [x] Rollback opisany
- [x] Approval użytkownika na start implementacji

## Definition of Done

- [x] Wszystkie punkty „Do zrobienia” zamknięte
- [x] Test plan wykonany (wyniki udokumentowane)
- [x] Brak nieplanowanych zmian poza zakresem
- [x] Review użytkownika (jeśli wymagane)
- [x] ADR/runbook zaktualizowane (jeśli dotyczy)

## Test plan

1. **Static config check (Ansible vars/template):**
   - `cd /Users/karolkurek/repos/homeserver-services`
   - `ansible-playbook playbooks/tests/openclaw-coding-agent-smoke.yml -i inventory/hosts.yml --syntax-check`
   - Oczekiwane: `exit 0`.

2. **Render i walidacja LibreChat config:**
   - po deploy: `docker exec librechat cat /app/librechat.yaml | rg "openclaw/coding_agent|modelSpecs|enforce"`
   - Oczekiwane: `openclaw/coding_agent` obecny, `enforce: true`.

3. **UI smoke:**
   - Wejść na `https://t630.colobus-micro.ts.net/chat/`.
   - Oczekiwane: dropdown zawiera „Coding …”; wybór nie powoduje błędu 4xx/5xx.

4. **Gateway/API smoke dla coding_agent:**
   - `curl -sS -H "Authorization: Bearer $TOKEN" https://t630.colobus-micro.ts.net/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"openclaw/coding_agent","messages":[{"role":"user","content":"Podaj krótkie git status check command"}]}'`
   - Oczekiwane: odpowiedź 200 z kompletacją.

5. **Tool policy smoke (bez deploy action):**
   - prompt testowy do `coding_agent` o `git_status` i `docker_status` (read-only).
   - Oczekiwane: narzędzia dostępne; brak użycia messaging.

6. **Negatywny smoke (guardrails):**
   - sprawdzić, że `openclaw/infra_agent` i `openclaw/main` nadal nie są widoczne w LibreChat.

## Test plan (wykonany)

| Komenda/scenariusz | Kiedy | Oczekiwany wynik | Wynik rzeczywisty | Dowód/link | Wyjątki/notatki |
|--------------------|-------|------------------|-------------------|------------|-----------------|
| `ansible-playbook playbooks/tests/openclaw-coding-agent-smoke.yml -i inventory/hosts.yml --syntax-check` | 2026-05-23 11:44 CEST | `exit 0` | `exit 0` | sesja terminala | syntaks smoke OK |
| `docker exec librechat grep -n "openclaw/coding_agent\\|enforce:" /app/librechat.yaml` | 2026-05-23 11:44 CEST | `enforce: true`, model obecny | obecne (`enforce: true`, `openclaw/coding_agent`) | sesja terminala | config runtime potwierdzony |
| `curl /v1/chat/completions model=openclaw/default` (z hosta T630) | 2026-05-23 11:44 CEST | HTTP 200 | HTTP 200 | sesja terminala | smoke bazowy OK |
| `curl /v1/chat/completions model=openclaw/coding_agent` (z hosta T630) | 2026-05-23 11:44 CEST | HTTP 200 | HTTP 200 | sesja terminala | smoke coding OK |
| `grep "openclaw/infra_agent\\|openclaw/main" /app/librechat.yaml` | 2026-05-23 11:45 CEST | brak wpisów | brak wpisów | sesja terminala | negatywny guardrail OK |

## Work log

- `docs/worklog/EPIC-007/SPEC-007H-2026-05-23-coding-agent-librechat.md`

## Rollback

1. Cofnąć preset `openclaw/coding_agent` z `librechat_openclaw_models`.
2. Przywrócić `openclaw/coding_agent` do `librechat_openclaw_models_forbidden`.
3. Redeploy `--tags librechat`.
4. Zweryfikować UI/API, że model nie jest wybieralny.

## Prompt plan

1. Czytaj: `SPEC-007C`, `SPEC-007F`, ten SPEC, runbook LibreChat.
2. Nie ruszaj sekretów i `~/.openclaw`.
3. Wprowadź minimalną zmianę allowlisty modeli w LibreChat.
4. Zweryfikuj polityki `coding_agent` i opisz jawnie ryzyka.
5. Uruchom smoke i uzupełnij `Test plan (wykonany)`.
6. Zaktualizuj runbook + EPIC child table + worklog.

## Na później

- Rozważyć osobny „secure profile” dla `coding_agent` w LibreChat (np. read-only preset bez `ops_deploy`) jako alternatywa do pełnego profilu.
- Rozważyć 2FA/ACL na dostęp do instancji LibreChat przed szerszym udostępnieniem presetu `coding_agent`.
