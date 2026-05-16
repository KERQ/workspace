# Workspace checks

Walidacja struktury AI-Native Workspace (SPEC-002). Bez deployu, bez skanu repo domenowych, bez odczytu sekretów.

## Uruchomienie

```bash
cd ~/repos/workspace
./scripts/checks/workspace/check_workspace_structure.sh
```

Exit code `0` = OK, `1` = błędy.

## Co sprawdza

- Pliki root: `PROJEKT.md`, `BACKLOG.md`, `AGENTS.md`, `README.md`
- Katalogi: `specs/`, `contracts/`, `docs/adr/`, `docs/runbooks/`, `scripts/checks/`
- Szablony SPEC, EPIC, ADR
- Kontrakty MVP (deploy, ansible, services, secrets, repos)
- 5 symlinków repo + `.git` w celu
- 5 kluczy w `contracts/repos/repositories.yml`
- Brak oczywistych plików sekretów w **root** workspace (tylko nazwy)

## Czego nie robi

- Nie wchodzi rekurencyjnie w `homeserver-core/`, itd.
- Nie uruchamia Ansible ani deploy
- Nie czyta treści `.env` / tokenów

## Przed commitem workspace

```bash
./scripts/checks/workspace/check_workspace_structure.sh
git status   # upewnij się, że pod symlinkami nie ma staged files z repo domenowych
```

Nie używaj `git add homeserver-core/*` — może dodać pliki z repo domenowego.
