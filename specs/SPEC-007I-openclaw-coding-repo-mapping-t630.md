# SPEC-007I: T630 — multi-repo context dla `coding_agent` (OpenClaw)

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: draft
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: high
Type: infra + config + docs
Zablokowany przez: [SPEC-007H](SPEC-007H-librechat-coding-agent-full-config.md) **done**
Blokuje: —

## Cel

Zapewnić, że `coding_agent` na T630 ma kontekst **wszystkich repozytoriów z katalogu `REPOS`**, z `workspace` jako głównym punktem wejścia, tak aby narzędzia `git_status`/`ai_dev` działały przewidywalnie w LibreChat/OpenClaw.

## Kontekst

Stan bieżący (zweryfikowany na T630, 2026-05-23):

- `/usr/local/bin/git_status` ma `DEFAULT_REPO_PATH = /opt/homeserver-ansible-repo`.
- `/opt/homeserver-ansible-repo` **nie istnieje**.
- `/opt/homeserver-services` nie jest checkoutem Git.
- `/opt/openclaw-control-plane` jest checkoutem Git.

To oznacza, że `coding_agent` może odpowiadać tekstowo, ale operacje repo są niespójne i zależne od ręcznego podawania ścieżek.

## Decyzja docelowa (rekomendowana)

Ustawić kanoniczny katalog pracy `coding_agent` na T630 jako checkout `workspace` na ścieżce:

- `/opt/repos/workspace`

oraz wymusić to przez Ansible:

- `openclaw_coding_agent_repo_path: "/opt/repos/workspace"`
- provisioning/aktualizacja checkoutu Git (Forgejo `origin`) dla `workspace`,
- provisioning/aktualizacja checkoutów wszystkich repo domenowych w `REPOS/`,
- symlinki w `workspace/` do repo domenowych, zgodne z modelem workspace.

## Repozytoria w kontekście OpenClaw

Źródło prawdy: `workspace/contracts/repos/repositories.yml` oraz symlinki w `workspace/`.

| Repo | Rola w kontekście `coding_agent` | Write policy |
|------|----------------------------------|--------------|
| `workspace` | główny punkt wejścia: SPEC, EPIC, contracts, runbooki, worklog | write po approval |
| `homeserver-core` | infra bazowa: Docker, Tailscale, Caddy, monitoring, backup | write po osobnym SPEC/approval |
| `homeserver-services` | OpenClaw, LibreChat, LiteLLM, Paperclip, Airflow | write po osobnym SPEC/approval |
| `life-platform` | Home Assistant, MQTT, Zigbee2MQTT, ESPHome | write po osobnym SPEC/approval |
| `investment-research` | research/ML/IP, wysoka prywatność | read-first; każdy write wymaga osobnego approval |
| `openclaw-control-plane` | policy, agents, memory, governance | write po SPEC; policy changes wymagają ADR |

Repo zależne operacyjnie, które muszą być dostępne jako kontekst przy pracy nad T630:

- `contracts/deploy/t630-deploy-order.yml` — kolejność deployu: `homeserver-core` -> `life-platform` / `homeserver-services`.
- `contracts/ansible/role-ownership.yml` — właścicielstwo ról Ansible per repo.
- `contracts/services/ports.yml` — porty i właściciele usług.
- `contracts/secrets/scopes.yml` — scope sekretów; bez czytania wartości sekretów.

Dlaczego ten wariant:

- zgodny z Twoim wymaganiem: pełny kontekst repo + `workspace` jako główny,
- zgodny z modelem `workspace` (symlinki do repo domenowych),
- ogranicza dryf między planowaniem (`workspace/specs`) i implementacją w repo domenowych.

## Alternatywa (fallback)

Szybki hotfix: ustawić `openclaw_coding_agent_repo_path` na istniejące `/opt/openclaw-control-plane`.

- Plus: natychmiastowe działanie `git_status`.
- Minus: brak kontekstu wszystkich repo z `REPOS` i rozjazd względem `workspace`.

## Zakres

### In scope

- Ustalenie i wdrożenie jednej kanonicznej ścieżki głównej (`workspace`) dla `coding_agent` na T630.
- Zapewnienie istnienia checkoutów Git dla wszystkich repo w `REPOS`.
- Zapewnienie symlinków `workspace -> repo domenowe` na T630.
- Zapewnienie, że `coding_agent` startuje od `workspace/AGENTS.md`, `PROJEKT.md`, `contracts/repos/repositories.yml` i właściwych kontraktów zależnych.
- Regeneracja wrappera `git_status` przez rolę OpenClaw.
- Smoke testy `git_status` i prosty chat completion dla `openclaw/coding_agent`.
- Aktualizacja runbooków i kontraktu operacyjnego.

### Out of scope

- Refactor polityk narzędzi `coding_agent`.
- Zmiany semantyki narzędzi w `policies/tool-allowlist.yml` (poza tekstowym doprecyzowaniem kontraktów agentów).
- Migracja historii lub pełne przełączanie wszystkich runtime path poza T630.

## Pliki / obszary

### Read

- `homeserver-services/roles/openclaw/defaults/main.yml`
- `homeserver-services/roles/openclaw/templates/git-status.sh.j2`
- `homeserver-services/roles/openclaw/tasks/main.yml`
- `homeserver-services/inventory/host_vars/t630.yml`
- `homeserver-services/docs/runbooks/openclaw-project-workflow.md`
- `workspace/docs/runbooks/t630-openclaw-gateway-librechat.md`

### Write

- `homeserver-services/inventory/host_vars/t630.yml` (repo root + `openclaw_coding_agent_repo_path` + lista repo do synchronizacji)
- `homeserver-services/roles/openclaw/*` (jeśli brak mechanizmu zapewnienia checkoutu)
- `homeserver-services/docs/runbooks/openclaw-project-workflow.md`
- `workspace/docs/runbooks/t630-openclaw-gateway-librechat.md` (sekcja troubleshooting/repo mapping)
- `workspace/specs/epics/EPIC-007-openclaw-gateway-librechat.md` (child table)
- `openclaw-control-plane/agents/coding_agent/{AGENTS.md,USER.md,TOOLS.md}`
- `openclaw-control-plane/agents/main/{AGENTS.md,USER.md,TOOLS.md}`
- `openclaw-control-plane/agents/orchestrator/{AGENTS.md,USER.md,TOOLS.md}`
- `openclaw-control-plane/agents/infra_agent/{AGENTS.md,USER.md}`
- `openclaw-control-plane/agents/ha_config_agent/{AGENTS.md,USER.md}`
- `openclaw-control-plane/agents/finance_agent/{AGENTS.md,USER.md}`
- `openclaw-control-plane/agents/research_agent/{AGENTS.md,USER.md}`
- `openclaw-control-plane/agents/personal_agent/{AGENTS.md,USER.md}`
- `openclaw-control-plane/agents/smart_home_agent/{AGENTS.md,USER.md}`

### Forbidden

- Sekrety w `host_vars` (poza istniejącymi kluczami, bez ujawniania wartości)
- Manualna edycja `~/.openclaw/openclaw.json` jako trwałe rozwiązanie

## Do zrobienia

- [ ] Wybrać kanoniczną ścieżkę repo głównego na T630 (rekomendacja: `/opt/repos/workspace`).
- [ ] Zapewnić checkout Git dla `workspace` w tej ścieżce (Ansible-managed).
- [ ] Zapewnić checkouty Git wszystkich repo domenowych w `REPOS`.
- [ ] Zapewnić symlinki z `workspace` do repo domenowych.
- [ ] Zapisać w konfiguracji/kontrakcie listę repo kontekstowych i zależności operacyjnych.
- [ ] Ustawić `openclaw_coding_agent_repo_path` na `workspace` w `host_vars/t630.yml`.
- [ ] Wykonać **Agent contracts alignment**: `coding_agent`/`orchestrator`/`main` pełny update pod model `workspace + multi-repo`.
- [ ] Wykonać **Agent contracts alignment**: `infra`/`ha_config`/`finance`/`research`/`personal`/`smart_home` krótkie doprecyzowanie granic routingu i write policy względem `coding_agent`.
- [ ] Wykonać deploy `--tags openclaw`.
- [ ] Potwierdzić, że `/usr/local/bin/git_status` wskazuje nową ścieżkę domyślną.
- [ ] Uruchomić smoke: `/usr/local/bin/git_status` zwraca `"ok": true`.
- [ ] Uruchomić smoke: `/v1/chat/completions` dla `openclaw/coding_agent` i prompt wymagający checku repo.
- [ ] Zaktualizować runbooki o finalny mapping repo.

## Definition of Ready

- [ ] Cel i zakres są jasne
- [ ] Wybrana docelowa ścieżka repo
- [ ] Test plan zdefiniowany
- [ ] Rollback opisany
- [ ] Approval użytkownika na start implementacji

## Definition of Done

- [ ] `openclaw_coding_agent_repo_path` wskazuje istniejący checkout `workspace` na T630
- [ ] Wszystkie repo z `REPOS` istnieją jako checkouty Git
- [ ] `workspace` ma poprawne symlinki do repo domenowych
- [ ] `coding_agent` ma udokumentowaną mapę repo i zależności operacyjnych
- [ ] Kontrakty wszystkich agentów są spójne z modelem `workspace + multi-repo`
- [ ] `git_status` działa bez podawania argumentu ścieżki
- [ ] Smoke `openclaw/coding_agent` przechodzi
- [ ] Runbooki zaktualizowane
- [ ] Wyniki testów wpisane do SPEC/worklog

## Test plan

1. **Pre-check workspace and repos (T630):**
   - `ssh t630@192.168.1.20 'test -d /opt/repos/workspace/.git && echo WORKSPACE_OK || echo WORKSPACE_MISSING'`
   - `ssh t630@192.168.1.20 'for r in homeserver-core homeserver-services life-platform investment-research openclaw-control-plane; do test -d /opt/repos/$r/.git && echo \"$r OK\" || echo \"$r MISSING\"; done'`

2. **Deploy OpenClaw config/wrappers:**
   - `APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags openclaw`

3. **Wrapper check:**
   - `ssh t630@192.168.1.20 'grep -n "DEFAULT_REPO_PATH" /usr/local/bin/git_status'`

4. **Git tool smoke:**
   - `ssh t630@192.168.1.20 '/usr/local/bin/git_status'`
   - oczekiwane: JSON z `"ok": true`

5. **Workspace link smoke:**
   - `ssh t630@192.168.1.20 'for r in homeserver-core homeserver-services life-platform investment-research openclaw-control-plane; do test -L /opt/repos/workspace/$r && echo \"$r LINK_OK\" || echo \"$r LINK_MISSING\"; done'`

6. **Gateway coding smoke:**
   - `ssh t630@192.168.1.20 'source /opt/homeserver-services/t630-config/librechat/.env; curl -sS http://127.0.0.1:18789/v1/chat/completions -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" -H "Content-Type: application/json" -d '{"model":"openclaw/coding_agent","messages":[{"role":"user","content":"sprawdź status repo"}]}'`'
   - oczekiwane: HTTP 200 i odpowiedź bez błędu repo path

## Test plan (wykonany)

| Komenda/scenariusz | Kiedy | Oczekiwany wynik | Wynik rzeczywisty | Dowód/link | Wyjątki/notatki |
|--------------------|-------|------------------|-------------------|------------|-----------------|
| do uzupełnienia po implementacji | — | — | — | — | — |

## Rollback

1. Przywrócić poprzednią wartość `openclaw_coding_agent_repo_path`.
2. Redeploy `--tags openclaw`.
3. Zweryfikować `git_status` i `/v1/chat/completions`.

## Work log

- dodać wpis: `docs/worklog/EPIC-007/SPEC-007I-YYYY-MM-DD-coding-repo-mapping.md`

## Prompt plan

1. Najpierw sprawdź aktualny stan checkoutu na T630.
2. Wprowadź minimalne zmiany Ansible dla stałej ścieżki repo.
3. Zdeployuj tylko `openclaw`.
4. Uruchom smoke `git_status` i `coding_agent`.
5. Zaktualizuj runbook + worklog + status SPEC.
