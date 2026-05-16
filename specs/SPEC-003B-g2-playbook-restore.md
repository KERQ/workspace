# SPEC-003B: Playbook G2 dla homeserver-services

Parent: SPEC-003
Status: done
Repo: homeserver-services
Owner: karolkurek
Risk: medium
Type: infra

## Cel

Dostarczyć brakujący `playbooks/g2.yml` w `homeserver-services`, żeby dokumentacja, `ops-run.sh preflight` i check SPEC-003 były spójne z rzeczywistością — **bez deployu na G2** w tej iteracji.

## Kontekst

- SPEC-003 dodał check — exit **1** z powodu braku `g2.yml`.
- `git log -- playbooks/g2.yml` → **pusta historia** (plik nigdy nie był w repo).
- „Przywrócenie z Git” **nie jest możliwe** — utworzono playbook od zera (wzorzec `t630.yml`).
- `scripts/deploy-g2.sh` nadal brak — **SPEC-003C** / EPIC-002.

## Wynik investigacji (2026-05-16)

| Element | Stan |
|---------|------|
| `playbooks/g2.yml` | **utworzony** (SPEC-003B) |
| Historia Git pliku | brak (create, nie restore) |
| `inventory/hosts.yml` | `g2` zdefiniowany |
| `inventory/host_vars/g2.yml` | lokalnie (gitignored) |
| Role G2 services | `trading` |

## Zakres

### In scope

- [x] Utworzyć `playbooks/g2.yml`
- [x] `ansible-playbook --syntax-check playbooks/g2.yml`
- [x] `check_playbooks.sh` → exit 0
- [x] Doprecyzować `multi-repo-deploy.md`
- [x] Ten SPEC w workspace

### Out of scope

- Deploy na G2
- `scripts/deploy-g2.sh`
- Masowa naprawa runbooków `homeserver-ansible`

## Pliki zmienione

- `homeserver-services/playbooks/g2.yml`
- `homeserver-services/docs/runbooks/multi-repo-deploy.md`
- `homeserver-services/scripts/checks/ansible-playbooks/README.md`

## Do zrobienia

- [x] Utworzyć `playbooks/g2.yml`
- [x] Syntax-check i check SPEC-003
- [x] Aktualizacja runbooka
- [x] Commity (po implementacji)

## Definition of Done

- [x] `playbooks/g2.yml` w repo
- [x] Syntax-check lokalny OK
- [x] Check SPEC-003 zielony
- [x] Brak deployu na G2
- [x] Commity w obu repo

## Test plan (wykonany)

1. `ansible-playbook --syntax-check playbooks/g2.yml` → 0
2. `check_playbooks.sh` → 0
3. `check_playbooks.sh --syntax-check` → 0

## Na później

- **SPEC-003C:** `scripts/deploy-g2.sh` + `ops-run.sh deploy-g2`
- Runbooki: `homeserver-ansible` → `homeserver-services`
