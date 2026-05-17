# Plan wdrożenia AI-Native Workspace Operating Model

**Status:** zatwierdzone z modyfikacjami  
**Data:** 2026-05-16  
**Założenie nadrzędne:** nie zmieniamy systemu operacyjnego hostów. Nie migrujemy teraz do NixOS. Ansible zostaje, ale dostaje lepszą warstwę koordynacji, standard pracy i bramki kontroli.

---

## 1. Podsumowanie rozmowy

### 1.1. Cel

Chcesz ułatwić pracę nad obecnym projektem i przyszłymi projektami przez przejście na bardziej uporządkowany, agent-friendly model pracy:

- mniej ręcznego kodowania,
- więcej pracy przez specyfikacje, testy i review,
- jeden kontekst dla agentów AI,
- kontrolowane zmiany przez diff, approval i PR,
- brak automatycznego merge/deploy bez człowieka,
- większa ochrona prywatnych repo i sekretów.

### 1.2. Zatwierdzony kierunek

Zatwierdzamy kierunek strategiczny:

```text
AI-Native Workspace Operating Model

single workspace context
multi-repo execution
file-based specs
test-first implementation
local Git/PR/review
human approval gates
selective GitHub backup
```

Nie wdrażamy tego jako big-bang platform project. Wdrażamy etapami.

### 1.3. Najważniejsze decyzje

| Obszar | Decyzja |
|---|---|
| Monorepo | Nie robimy teraz pełnego monorepo dla obecnego systemu. |
| Workspace | Tworzymy jeden root kontekstowy `~/repos/workspace/`. |
| Repo | Obecne repozytoria zostają osobne. |
| Ansible | Zostaje, ale dokładamy nadrzędny deploy orchestration layer. |
| OS | Nie zmieniamy systemu operacyjnego. Brak migracji do NixOS. |
| Nix | Opcjonalnie tylko jako package manager/devshell w przyszłości, bez zmiany OS. |
| Forgejo | Docelowo lokalny Git/PR/review system of record. |
| GitHub | Backup/mirror tylko selektywnie, nie dla wszystkiego. |
| OpenClaw | Centralny policy/memory/execution/approval layer. |
| LibreChat/LobeChat | Cienki UI do delegowania przez OpenClaw `/v1`. |
| difit | Preview patcha przed commitem i PR. |
| Bot Forgejo | Później, najpierw tylko read/comment/review. |
| Automatyczny deploy | Nie. Deploy manual only. |
| Merge | Manual only. |
| Sekrety | Agents: deny by default. |

---

## 2. Obecny podział repozytoriów

Docelowo zachowujemy obecny podział domenowy:

```text
homeserver-core          infra/stateful
homeserver-services      usługi/runtime/deploy
life-platform            smart home / personal domain
investment-research      ML / research / IP
openclaw-control-plane   policy / agents / memory / governance
```

### 2.1. Odpowiedzialności repo

| Repo | Odpowiedzialność | Uwagi |
|---|---|---|
| `homeserver-core` | base OS config, Docker, Tailscale, Caddy, monitoring, backup, storage | high risk, deploy manual only |
| `homeserver-services` | OpenClaw, LiteLLM, Paperclip, Airflow, runtime services | high risk, wymaga review przy Docker/systemd/Caddy |
| `life-platform` | Home Assistant, Mosquitto, Zigbee2MQTT, ESPHome, personal domains | privacy-sensitive |
| `investment-research` | research, ML, backtest, trading, IP | hard privacy wall, brak GitHub mirror by default |
| `openclaw-control-plane` | agents, policies, registry, memory, governance, UI/API | policy changes require ADR |

---

## 3. Docelowy model workspace

Nie scalać historii Git i lifecycle repozytoriów. Zamiast tego stworzyć workspace, który jest wspólnym punktem wejścia dla człowieka i agentów.

```text
~/repos/workspace/
├── README.md
├── PROJEKT.md
├── BACKLOG.md
├── AGENTS.md
├── docs/
│   ├── adr/
│   └── runbooks/
├── specs/
│   ├── README.md
│   ├── templates/
│   ├── core/
│   ├── services/
│   ├── life/
│   ├── research/
│   └── control-plane/
├── contracts/
│   ├── openapi/
│   ├── events/
│   └── ansible-vars/
├── deploy/
│   ├── README.md
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── scripts/
│   │   ├── deploy-t630-full.sh
│   │   ├── deploy-g2-full.sh
│   │   ├── check-deploy-boundaries.sh
│   │   └── check-inventory-drift.sh
│   ├── tests/
│   │   ├── test_full_deploy_order.py
│   │   ├── test_inventory_hosts_consistent.py
│   │   ├── test_no_cross_repo_roles.py
│   │   ├── test_secret_paths.py
│   │   └── test_tag_contracts.py
│   └── docs/
│       └── deploy-boundaries.md
├── scripts/
│   ├── bootstrap.sh
│   ├── sync.sh
│   ├── test-all.sh
│   └── check-all.sh
├── homeserver-core/
├── homeserver-services/
├── life-platform/
├── investment-research/
└── openclaw-control-plane/
```

Repozytoria mogą być zwykłymi lokalnymi checkoutami albo submodules. Na start lepiej nie blokować się na decyzji o submodules. Najważniejsze, żeby workspace był stałym rootem pracy.

---

## 4. Standard pracy: specs zamiast luźnych zadań

Każda większa zmiana powinna startować od pliku specyfikacji.

### 4.1. Nazewnictwo

```text
specs/<obszar>/SPEC-YYYYMMDD-NNN-krotki-slug.md
```

Przykłady:

```text
specs/services/SPEC-20260516-001-openclaw-forgejo-mvp.md
specs/core/SPEC-20260516-002-deploy-orchestration-layer.md
specs/life/SPEC-20260516-003-home-assistant-smoke-checks.md
```

### 4.2. Szablon specyfikacji

```markdown
# SPEC-YYYYMMDD-NNN: Nazwa zmiany

Status: draft | ready | in_progress | blocked | done
Repo: homeserver-services
Owner: Karol
Risk: low | medium | high | critical
Type: feature | bugfix | refactor | infra | research | ops
Created: YYYY-MM-DD

## 1. Cel

## 2. Kontekst

## 3. Zakres

### In scope
- ...

### Out of scope
- ...

## 4. Dotknięte repo / pliki

## 5. Definition of Ready

- [ ] wiemy, które repo są dotknięte
- [ ] wiemy, które testy trzeba uruchomić
- [ ] wiemy, czy zmiana dotyka sekretów
- [ ] wiemy, czy zmiana dotyka deployu
- [ ] jest plan rollbacku
- [ ] jest minimalny prompt plan dla agenta

## 6. Definition of Done

- [ ] testy jednostkowe przechodzą
- [ ] testy integracyjne / smoke przechodzą
- [ ] dokumentacja/runbook zaktualizowany
- [ ] ADR dodany, jeśli decyzja architektoniczna
- [ ] diff reviewed
- [ ] brak plaintext sekretów
- [ ] brak zmian poza zakresem specyfikacji

## 7. Scenariusze BDD

### Scenariusz 1
Zakładając, że ...
Gdy ...
Wtedy ...

## 8. Test plan

## 9. Rollback plan

## 10. Prompt plan

## 11. Na później
```

### 4.3. Reguła TODO

Dopuszczalne:

```text
TODO(SPEC-20260516-001): uprościć retry policy po migracji providera
```

Niedopuszczalne:

```text
TODO: AI kiedyś to poprawi
```

Agent nie naprawia długu technicznego „w wolnej chwili”. Dług trafia do backlogu albo specyfikacji.

---

## 5. Ansible: zostaje, ale dostaje deploy orchestration layer

### 5.1. Decyzja

Nie przenosimy teraz całego Ansible do jednego repo. Obecny split ma sens jako granica domenowa, ale jest słaby jako UX deployu.

Zmieniamy model z:

```text
człowiek pamięta kolejność:
cd homeserver-core && ansible-playbook ...
cd life-platform/... && ansible-playbook ...
cd homeserver-services && ansible-playbook ...
```

na:

```text
workspace/deploy/scripts/deploy-t630-full.sh
workspace/deploy/scripts/deploy-g2-full.sh
```

### 5.2. Docelowa odpowiedzialność warstw

```text
homeserver-core:
  - base OS config
  - docker
  - tailscale
  - caddy base
  - monitoring
  - backup
  - storage

life-platform:
  - Home Assistant
  - Mosquitto
  - Zigbee2MQTT
  - ESPHome
  - smart-home configs

homeserver-services:
  - OpenClaw
  - LiteLLM
  - Paperclip
  - Airflow
  - service-level compose/systemd
```

### 5.3. Canonical non-secret inventory

W workspace trzymamy canonical inventory bez sekretów:

```text
deploy/inventory/hosts.yml
```

Przykład:

```yaml
all:
  hosts:
    t630:
      ansible_host: 192.168.1.20
      ansible_user: t630
      layers:
        - core
        - life
        - services
    g2:
      ansible_host: 192.168.1.19
      ansible_user: g2
      layers:
        - core
        - services
```

Sekrety zostają per warstwa/repo i muszą być szyfrowane zgodnie z dotychczasową polityką.

### 5.4. Deploy scripts

```bash
# deploy/scripts/deploy-t630-full.sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[1/3] homeserver-core"
cd "$ROOT/homeserver-core"
ansible-playbook playbooks/t630.yml -l t630

echo "[2/3] life-platform"
cd "$ROOT/life-platform/domains/home/ansible"
ansible-playbook playbooks/t630.yml -l t630

echo "[3/3] homeserver-services"
cd "$ROOT/homeserver-services"
ansible-playbook playbooks/t630.yml -l t630
```

Analogicznie:

```text
deploy/scripts/deploy-g2-full.sh
deploy/scripts/deploy-t630-core.sh
deploy/scripts/deploy-t630-life.sh
deploy/scripts/deploy-t630-services.sh
```

### 5.5. Testy deploy boundaries

Dodać proste testy statyczne:

```text
deploy/tests/test_full_deploy_order.py
deploy/tests/test_inventory_hosts_consistent.py
deploy/tests/test_no_cross_repo_roles.py
deploy/tests/test_secret_paths.py
deploy/tests/test_tag_contracts.py
```

Celem nie jest perfekcyjna walidacja Ansible. Celem jest szybkie wykrywanie dryfu i pomyłek agentów.

---

## 6. OpenClaw + Forgejo + LibreChat + difit

### 6.1. Docelowa architektura

```text
Telefon / Laptop
      │
      ▼
LibreChat / LobeChat
      │
      ▼
OpenClaw Gateway /v1
      │
      ├── policy layer
      ├── memory layer
      ├── approval workflow
      └── task runner / worktree agent
              │
              ▼
            difit
              │
              ▼
          review diff
              │
              ▼
          Forgejo PR
              │
              ▼
       manual merge by human
              │
              ▼
    GitHub mirror selected repos
```

### 6.2. Zasady bezpieczeństwa

```yaml
default_policy:
  read_repo: allow
  create_worktree: allow
  write_worktree: allow_for_non_sensitive_repo
  run_tests: allow
  commit: requires_human_approval
  push_branch: requires_human_approval
  create_pr: allowed_after_commit_approval
  merge: never
  deploy: never
  secrets_access: deny
```

### 6.3. OpenClaw `/v1`

MVP:

```text
LibreChat -> OpenClaw /v1 tylko przez Tailscale + Caddy auth
OpenClaw agent używany przez LibreChat ma ograniczone tools
brak sekretów
brak deployu
brak merge
brak push na protected branches
```

Nie podłączać LibreChat do pełnego operator tokena, jeśli agent ma dostęp do narzędzi wrażliwych.

### 6.4. Forgejo

Forgejo docelowo jest lokalnym Git/PR/review system of record.

Startujemy od jednego repo:

```text
openclaw-control-plane
albo
homeserver-services
```

Nie migrujemy wszystkich repo naraz.

### 6.5. GitHub mirror

GitHub nie jest głównym miejscem pracy agentów. To backup/mirror dla wybranych repo.

| Repo | Mirror GitHub |
|---|---|
| `homeserver-core` | tak, później, po testach |
| `homeserver-services` | tak, później, po testach |
| `life-platform` | opcjonalnie |
| `investment-research` | nie jako default |
| `openclaw-control-plane` | tak, jeśli brak sekretów/runtime state |

Zasady:

```text
- najpierw manual push do github remote,
- potem mirror tylko po testach,
- branch filter: main, release/*,
- feature branches nie mirrorować na początku,
- investment-research: Forgejo + restic/MinIO/offsite encrypted backup.
```

---

## 7. Brak zmiany systemu operacyjnego

### 7.1. Decyzja

Nie migrujemy T630/G2 do NixOS. Nie wykonujemy in-place conversion. Nie reinstalujemy hostów.

### 7.2. Co zostaje

```text
OS obecny: zostaje
Ansible: zostaje
Docker Compose: zostaje
Tailscale/Caddy/systemd: zostają
```

### 7.3. Co można dodać później bez zmiany OS

Opcjonalnie, po ustabilizowaniu workspace:

```text
Nix package manager:
  - devshell dla Ansible
  - pinned Python/Node/pnpm
  - pinned ansible-lint
  - pinned OpenTofu
  - reproducible tools dla agentów
```

Ale to nie jest wymóg MVP.

---

## 8. Etapowy plan wdrożenia

## Etap 0 — standard pracy bez nowej infrastruktury

**Cel:** zacząć pracować nowym modelem bez Forgejo, LibreChat i dodatkowej infrastruktury.

Zadania:

- [ ] Utworzyć `~/repos/workspace`.
- [ ] Dodać `PROJEKT.md`.
- [ ] Dodać `BACKLOG.md`.
- [ ] Dodać `AGENTS.md`.
- [ ] Dodać `specs/templates/SPEC_TEMPLATE.md`.
- [ ] Dodać `docs/adr/`.
- [ ] Dodać `contracts/`.
- [ ] Podpiąć/umieścić lokalne repo w workspace.
- [ ] Wybrać jedną małą realną zmianę i przeprowadzić ją przez spec -> test -> patch -> review.

Acceptance criteria:

```text
Jedna zmiana przechodzi:
idea -> spec -> test -> patch -> review -> merge -> ADR/runbook
```

---

## Etap 1 — deploy orchestration layer dla obecnego Ansible

**Cel:** ujednolicić UX deployu bez scalania Ansible do jednego repo.

Zadania:

- [ ] Dodać `deploy/README.md`.
- [ ] Dodać `deploy/inventory/hosts.yml` bez sekretów.
- [ ] Dodać `deploy/scripts/deploy-t630-full.sh`.
- [ ] Dodać `deploy/scripts/deploy-g2-full.sh`.
- [ ] Dodać skrypty granularne: core/life/services.
- [ ] Dodać `deploy/docs/deploy-boundaries.md`.
- [ ] Dodać testy statyczne deploy boundaries.

Acceptance criteria:

```text
Z workspace da się uruchomić pełny deploy T630 i G2 jednym entrypointem.
Kolejność warstw jest zapisana w kodzie, nie w pamięci człowieka.
```

---

## Etap 2 — Forgejo MVP dla jednego repo

**Cel:** lokalny Git/PR/review bez migracji wszystkiego naraz.

Zadania:

- [ ] Postawić Forgejo + PostgreSQL.
- [ ] Włączyć dostęp tylko przez Tailscale/Caddy.
- [ ] Utworzyć organizację `KERQ`.
- [ ] Zaimportować jedno repo pilotażowe.
- [ ] Ustawić `origin = Forgejo`.
- [ ] Ustawić `github = GitHub` jako ręczny remote, bez mirror automatycznego.
- [ ] Zweryfikować SSH push/pull.
- [ ] Utworzyć testowy branch i PR.
- [ ] Dodać backup Forgejo DB + data.

Acceptance criteria:

```text
PR workflow działa lokalnie w Forgejo dla jednego repo.
GitHub nie jest jeszcze automatycznym mirror.
```

---

## Etap 3 — OpenClaw `/v1` + LibreChat/LobeChat

**Cel:** wygodne delegowanie z telefonu/laptopa bez mieszania pamięci.

Zadania:

- [ ] Włączyć OpenClaw `/v1/models`.
- [ ] Włączyć OpenClaw `/v1/chat/completions`.
- [ ] Ograniczyć endpoint do loopback/tailnet/private ingress.
- [ ] Dodać Caddy auth.
- [ ] Podłączyć LibreChat/LobeChat jako custom OpenAI endpoint.
- [ ] Wyłączyć LibreChat memory/RAG dla tego endpointu.
- [ ] Sprawdzić, że OpenClaw memory jest jedynym źródłem pamięci agentów.
- [ ] Ograniczyć tools agenta UI.

Acceptance criteria:

```text
LibreChat wysyła prompt do openclaw/default.
Agent nie ma dostępu do sekretów, deployu, merge ani protected push.
```

---

## Etap 4 — worktree + difit preview

**Cel:** diff-first workflow przed commitem.

Zadania:

- [ ] Ustalić katalog `/srv/worktrees` albo lokalny odpowiednik w workspace.
- [ ] Dodać procedurę tworzenia worktree per task.
- [ ] Zbudować pinned image dla `difit`.
- [ ] Uruchomić `difit` ręcznie na testowym worktree.
- [ ] Wystawić diff przez Tailscale + Basic Auth.
- [ ] Opisać flow: approve / reject / modify.

Acceptance criteria:

```text
Agent robi patch w worktree.
Ty widzisz diff przed commitem.
Commit następuje dopiero po approval.
```

---

## Etap 5 — Forgejo bot read/comment

**Cel:** dodać review automation bez prawa zapisu do repo.

Zadania:

- [ ] Utworzyć użytkownika `openclaw-bot`.
- [ ] Wygenerować token read/comment.
- [ ] Dodać webhook z Forgejo.
- [ ] Obsłużyć `/openclaw summarize`.
- [ ] Obsłużyć `/openclaw review`.
- [ ] Obsłużyć `/openclaw review tests`.
- [ ] Obsłużyć `/openclaw review privacy`.
- [ ] Publikować komentarze i status check.

Zakazy MVP:

```text
NO write repo
NO merge
NO deploy
NO /openclaw fix na początku
```

Acceptance criteria:

```text
Bot potrafi skomentować PR summary/review.
Bot nie może modyfikować kodu.
```

---

## Etap 6 — commit/push/PR po approval

**Cel:** agent może przejść od diffu do PR dopiero po decyzji człowieka.

Flow:

```text
spec ready
agent creates worktree
agent writes tests
agent writes patch
agent runs tests
difit preview
human approves
agent commits
human approves push
agent pushes branch
PR created
bot summarizes/reviews
human merges
```

Acceptance criteria:

```text
Brak automatycznego merge.
Brak automatycznego deploy.
Każdy commit/push ma approval.
```

---

## Etap 7 — selektywny GitHub mirror

**Cel:** backup kodu dla wybranych repo po stabilizacji Forgejo.

Zadania:

- [ ] Najpierw ręczny `git push github main --tags`.
- [ ] Test mirror na pustym repo testowym.
- [ ] Włączyć mirror dla `homeserver-core`.
- [ ] Włączyć mirror dla `homeserver-services`.
- [ ] Rozważyć `openclaw-control-plane`.
- [ ] Nie włączać domyślnie dla `investment-research`.
- [ ] Ustawić branch filter: `main`, `release/*`.
- [ ] Monitorować błędy mirror sync.

Acceptance criteria:

```text
Mirror nie wypycha feature branches.
Mirror nie dotyczy repo hard privacy.
```

---

## 9. Pierwszy sprint roboczy

Proponowany pierwszy sprint to nie infrastruktura, tylko przygotowanie podstaw pracy.

### Sprint 1: workspace foundation

- [ ] `TASK-001`: utworzyć `~/repos/workspace`.
- [ ] `TASK-002`: dodać `PROJEKT.md` z mapą systemu.
- [ ] `TASK-003`: dodać `BACKLOG.md`.
- [ ] `TASK-004`: dodać `AGENTS.md` dla workspace.
- [ ] `TASK-005`: dodać `specs/templates/SPEC_TEMPLATE.md`.
- [ ] `TASK-006`: dodać `deploy/README.md`.
- [ ] `TASK-007`: dodać `deploy/docs/deploy-boundaries.md`.
- [ ] `TASK-008`: dodać `deploy/scripts/deploy-t630-full.sh` w trybie draft.
- [ ] `TASK-009`: dodać `deploy/scripts/deploy-g2-full.sh` w trybie draft.
- [ ] `TASK-010`: wybrać małą zmianę pilotażową i opisać ją specyfikacją.

### Kryterium zakończenia sprintu

```text
Możemy zacząć każdą kolejną pracę od pliku SPEC.
Agent ma jeden root kontekstowy.
Deploy order jest zapisany w workspace.
Nie zmieniliśmy systemu operacyjnego.
Nie rozbiliśmy istniejącego deployu.
```

---

## 10. Decyzje odłożone

Nie decydujemy teraz:

- czy workspace ma być git submodule meta-repo,
- czy migrować wszystkie repo do Forgejo jednocześnie,
- czy włączać automatyczny GitHub mirror,
- czy dodawać SwarmClaw,
- czy dodawać autoloop,
- czy używać Nix devshell,
- czy przepisywać Ansible,
- czy robić pełnego Forgejo bota z `/fix`.

Te decyzje wrócą po MVP.

---

## 11. Stałe guardrails

```text
- no auto-merge
- no auto-deploy
- no secrets access for agents
- no protected branch push
- no direct runtime edits
- no plaintext .env/PAT/tokens
- no write outside current repo/worktree
- no LibreChat memory duplication
- no GitHub mirror for investment-research by default
- diff before commit
- approval before commit
- approval before push
- manual merge only
```

---

## 12. Jak pracujemy od teraz

Standard dla każdej większej zmiany:

```text
1. Dopisz pomysł do BACKLOG.md.
2. Utwórz SPEC w specs/<obszar>/.
3. Uzupełnij DoR, DoD, test plan, rollback plan.
4. Agent pisze najpierw testy.
5. Testy mają być czerwone.
6. Agent robi minimalny patch.
7. Agent uruchamia testy.
8. Pokazuje diff.
9. Człowiek zatwierdza commit.
10. Człowiek zatwierdza push/PR.
11. Człowiek merge’uje.
12. Jeśli decyzja architektoniczna: dopisz ADR.
13. Jeśli operacja: dopisz runbook/check script.
```

---

## 13. Krótki prompt startowy dla agenta

```text
Pracujemy w modelu AI-Native Workspace Operating Model.

Zasady:
- Nie zmieniaj systemu operacyjnego.
- Nie migruj do NixOS.
- Ansible zostaje, ale deploy ma przechodzić przez workspace/deploy.
- Zaczynaj od SPEC w specs/.
- Najpierw testy, potem implementacja.
- Nie czytaj ani nie modyfikuj sekretów.
- Nie commituj bez approval.
- Nie pushuj bez approval.
- Nie merge’uj.
- Nie deployuj.
- Pokaż diff i test results przed kolejnym krokiem.

Pierwszy krok:
Przeczytaj PROJEKT.md, AGENTS.md, BACKLOG.md oraz właściwy SPEC.
Następnie zaproponuj minimalny plan zmian i test plan.
```

---

## 14. Finalna rekomendacja

Najlepsze docelowe rozwiązanie dla obecnej sytuacji:

```text
Workspace-first, not monorepo-first.
Ansible stays, deploy orchestration added.
OpenClaw becomes policy/memory/execution layer.
Forgejo becomes local Git/PR/review system.
GitHub becomes selective backup.
LibreChat/LobeChat becomes delegation UI.
difit becomes pre-commit diff preview.
Human remains approval gate for commit, push, merge, deploy.
```

To jest rozwiązanie, na którym możemy zacząć pracować od razu bez reinstalacji systemów i bez ryzykownej migracji całej infrastruktury.
