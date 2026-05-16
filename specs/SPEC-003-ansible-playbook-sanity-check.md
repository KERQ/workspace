# SPEC-003: Ansible playbook sanity check

Parent:
Status: done
Repo: homeserver-services
Owner: karolkurek
Risk: low
Type: tooling

## Cel

Dodać trwały check w `homeserver-services`, który weryfikuje obecność wymaganych playbooków Ansible i opcjonalnie uruchamia `--syntax-check` — bez deployu na hostach i bez odczytu sekretów.

## Kontekst

- BACKLOG **Now**: pierwsza mała zmiana w repo domenowym (pełny flow po Fazie 1).
- Wybrany wariant **C** (wzór SPEC-002 workspace).
- Znany drift: `playbooks/g2.yml` cytowany w `AGENTS.md`, `ops-run.sh`, runbooku — plik **brak** w tree (kontrakt workspace: draft).
- `scripts/ops-run.sh preflight` wywołuje `--syntax-check playbooks/g2.yml` i pada przy braku pliku — check ma dać **wcześniejszy, czytelny** sygnał.

## Zakres

### In scope

- `scripts/checks/ansible-playbooks/check_playbooks.sh`
- `scripts/checks/ansible-playbooks/README.md`
- Wymagane playbooki: `playbooks/t630.yml`, `playbooks/g2.yml`
- Flaga `--syntax-check` (opcjonalna, lokalna)
- Ten plik SPEC w workspace

### Out of scope

- Przywracanie `g2.yml` z historii Git (osobny SPEC)
- `ansible-playbook` z apply na hostach (deploy)
- Zmiany w `contracts/` workspace bez review
- Odczyt `.env`, vault, host_vars z sekretami

## Pliki / obszary

### Read

- `playbooks/`
- `scripts/ops-run.sh` (preflight)
- `docs/runbooks/multi-repo-deploy.md`
- Workspace: `contracts/deploy/g2-deploy-order.yml` (informacyjnie)

### Write

- `homeserver-services/scripts/checks/ansible-playbooks/check_playbooks.sh`
- `homeserver-services/scripts/checks/ansible-playbooks/README.md`
- `workspace/specs/SPEC-003-ansible-playbook-sanity-check.md`

### Forbidden

- `inventory/host_vars/*` (sekrety)
- deploy scripts z `--include-disruptive` bez approval
- inne repo domenowe

## Do zrobienia

- [x] Utworzyć SPEC-003 w workspace
- [x] Skrypt + README w homeserver-services
- [x] `check_playbooks.sh` → exit 1 dopóki brak `g2.yml` (oczekiwane)
- [x] `check_playbooks.sh --syntax-check` — t630 syntax OK; exit 1 z powodu brak `g2.yml`
- [x] Commit homeserver-services
- [x] Commit workspace SPEC

## Definition of Ready

- [x] EPIC-001 / SPEC-002 done
- [x] Wybór wariantu C

## Definition of Done

- [x] Skrypt wykonywalny, udokumentowany
- [x] Wymagane playbooki sprawdzane; brak `g2.yml` raportowany explicite
- [x] `--syntax-check` działa dla istniejących playbooków
- [x] Brak deployu, brak odczytu sekretów
- [x] Commity w obu repo

## Test plan

1. `cd ~/repos/homeserver-services && ./scripts/checks/ansible-playbooks/check_playbooks.sh` → exit **1**, komunikat o `g2.yml`
2. `.../check_playbooks.sh --syntax-check` → syntax-check `t630.yml` OK; exit **1** z powodu `g2.yml`
3. (Po przyszłym przywróceniu `g2.yml`) oba → exit **0**
4. Workspace check: `./scripts/checks/workspace/check_workspace_structure.sh` → 0

## Rollback

Usunąć `scripts/checks/ansible-playbooks/`. Brak wpływu na infra.

## Prompt plan

1. Czytaj ten SPEC i `AGENTS.md` w services
2. Tylko `scripts/checks/ansible-playbooks/`
3. Nie cat host_vars; nie ansible-playbook bez `--syntax-check`
4. Commit osobno: services vs workspace

## Na później

- SPEC-003B: przywrócić `playbooks/g2.yml` lub zaktualizować docs/kontrakt
- Podpiąć check do `ops-run.sh preflight` (osobna zgoda)
