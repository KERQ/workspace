# SPEC-002: Workspace consistency checks

Parent: EPIC-001
Status: done
Repo: workspace
Owner: karolkurek
Risk: low
Type: tooling

## Cel

Dodać pierwszy trwały check w `scripts/checks/workspace/`, który waliduje strukturę AI-Native Workspace i podstawowe contracts — bez dotykania repo domenowych ani infrastruktury.

## Kontekst

- Faza 1 (EPIC-001) dostarczyła skeleton workspace.
- BACKLOG Next: pierwszy realny SPEC po Fazie 1.
- Przed pierwszym commitem workspace potrzebujemy powtarzalnej walidacji lokalnej.
- Zgodnie z `scripts/checks/README.md`: diagnostyka jako artefakt, nie jednorazowe komendy z czatu.

## Zakres

### In scope

- Skrypt `scripts/checks/workspace/check_workspace_structure.sh`
- Sprawdzenia struktury, contracts, symlinków, braku oczywistych sekretów w root
- Exit code 0 = OK, non-zero = błędy (do użycia w test plan / CI później)
- Krótki README w `scripts/checks/workspace/README.md`

### Out of scope

- Deploy, Ansible, restart usług
- Głęboki skan repo domenowych (tylko: symlink istnieje + `.git` w celu)
- Odczyt wartości sekretów
- `git commit` (osobna decyzja użytkownika)
- Zmiany w repo domenowych

## Pliki / obszary

### Read

- `PROJEKT.md`, `AGENTS.md`, `README.md`
- `contracts/deploy/*.yml`, `contracts/ansible/role-ownership.yml`
- `contracts/services/ports.yml`, `contracts/secrets/scopes.yml`
- `contracts/repos/repositories.yml`
- `specs/SPEC-000-template.md`, `specs/epics/EPIC-000-template.md`
- `docs/adr/ADR-000-template.md`
- Symlinki: `homeserver-core`, `homeserver-services`, `life-platform`, `investment-research`, `openclaw-control-plane` (tylko `test -L`, `readlink`, `test -d <target>/.git`)

### Write

- `scripts/checks/workspace/check_workspace_structure.sh`
- `scripts/checks/workspace/README.md`
- `specs/SPEC-002-workspace-consistency-checks.md` (ten plik)

### Forbidden

- `homeserver-core/**`, `homeserver-services/**`, `life-platform/**`, `investment-research/**`, `openclaw-control-plane/**` (poza sprawdzeniem symlink + `.git`)
- `.env`, vault, token files — nie otwierać, nie cat
- `ansible-playbook`, deploy scripts na hostach

## Do zrobienia

- [x] Utworzyć `scripts/checks/workspace/check_workspace_structure.sh`
- [x] Root: PROJEKT.md, BACKLOG.md, AGENTS.md, README.md
- [x] Katalogi: specs, contracts, docs/adr, docs/runbooks, scripts/checks
- [x] Templates: specs/SPEC-000-template.md, specs/epics/EPIC-000-template.md, docs/adr/ADR-000-template.md
- [x] Kontrakty: deploy/t630, deploy/g2, ansible/role-ownership, services/ports, secrets/scopes, repos/repositories
- [x] 5 symlinków repo + cel z `.git`
- [x] `repositories.yml`: 5 kluczy repo
- [x] Root: brak oczywistych sekretów (maxdepth 1, tylko nazwy plików)
- [x] Uruchomić skrypt lokalnie — exit 0
- [x] Commit workspace + push `origin/main`

## Definition of Ready

- [x] EPIC-001 skeleton istnieje
- [x] Użytkownik zaakceptował plan tej sesji
- [x] `.gitignore` zaakceptowany

## Definition of Done

- [x] Skrypt istnieje i jest wykonywalny (`chmod +x`)
- [x] `./scripts/checks/workspace/check_workspace_structure.sh` zwraca 0 na obecnym workspace
- [x] Skrypt nie wchodzi rekurencyjnie w repo domenowe
- [x] Dokumentacja uruchomienia w README checka
- [x] Brak zmian w repo domenowych
- [x] `git init`, commit (`ef7e011`), merge i push GitHub (`87800f5`)

## Test plan

1. Z `~/repos/workspace`: `./scripts/checks/workspace/check_workspace_structure.sh` → exit 0
2. Tymczasowo przemianować `PROJEKT.md` → skrypt fail → przywrócić → exit 0
3. Tymczasowo usunąć symlink (lokalnie) → fail → przywrócić symlink
4. Przed commitem: `git status` — brak staged files z repo domenowych pod symlinkami

## Rollback

Usunąć `scripts/checks/workspace/` i `specs/SPEC-002-*.md`. Brak wpływu na infra i repo domenowe.

## Prompt plan

1. Przeczytaj `AGENTS.md`, `specs/SPEC-002-workspace-consistency-checks.md`
2. Implementuj tylko `scripts/checks/workspace/` + ewentualny README
3. Użyj `[[ -f ]]`, `[[ -d ]]`, `[[ -L ]]`, `readlink` — bez `find` w symlinkowanych repo
4. Sekrety: tylko lista w **root** workspace (maxdepth 1)
5. Nie uruchamiaj deployu; nie commituj bez approval

## Na później

- Hook pre-commit w workspace repo
- Check drift kontraktu vs runbooki w repo domenowych
- CI (Forgejo) po Etapie 2
