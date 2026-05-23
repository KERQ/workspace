# SPEC-007H — worklog (2026-05-23)

## Zakres sesji

- Włączenie `openclaw/coding_agent` do allowlisty modeli LibreChat.
- Aktualizacja runbooków i EPIC-007.
- Deploy `--tags librechat` na T630.
- Weryfikacja runtime i smoke API dla `openclaw/default` oraz `openclaw/coding_agent`.

## Zmiany

### homeserver-services

- `roles/librechat/defaults/main.yml`
  - dodano model:
    - id: `openclaw/coding_agent`
    - label: `Coding (FS/Runtime/Deploy)`
  - usunięto `openclaw/coding_agent` z `librechat_openclaw_models_forbidden`
- `docs/runbooks/openclaw-project-workflow.md`
  - dodano sekcję „LibreChat: wybór coding_agent”

### workspace

- `docs/runbooks/t630-openclaw-gateway-librechat.md`
  - dodano `coding_agent` do listy modeli i guardrails
- `specs/epics/EPIC-007-openclaw-gateway-librechat.md`
  - dodano child SPEC-007H
- `specs/SPEC-007H-librechat-coding-agent-full-config.md`
  - status `done`, uzupełniony test plan (wykonany), DoD, link do worklog

## Deploy

- Komenda:
  - `APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags librechat`
- Wynik:
  - `ok=14 changed=2 failed=0`
- Data/czas:
  - 2026-05-23 (CEST)

## Weryfikacja

1. `ansible-playbook playbooks/tests/openclaw-coding-agent-smoke.yml -i inventory/hosts.yml --syntax-check`
   - wynik: PASS (`exit 0`)
2. `docker exec librechat ... /app/librechat.yaml`
   - wynik: `enforce: true` i `openclaw/coding_agent` obecny
3. `/v1/chat/completions` dla `openclaw/default`
   - wynik: HTTP 200
4. `/v1/chat/completions` dla `openclaw/coding_agent`
   - wynik: HTTP 200
5. negatywny check `openclaw/infra_agent|openclaw/main` w `librechat.yaml`
   - wynik: brak wpisów

## Uwaga operacyjna

W logach `openclaw-gateway` widoczne są zdarzenia `ws unauthorized ... token_mismatch` dla klienta `clawsuite ui` (nie blokują smoke `chat/completions` dla LibreChat).

## Commity

- homeserver-services: `462111b`
- workspace: `a90415d`
