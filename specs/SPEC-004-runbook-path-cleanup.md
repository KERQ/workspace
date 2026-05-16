# SPEC-004: Runbook path cleanup (homeserver-ansible → homeserver-services)

Parent:
Status: done
Repo: homeserver-services (+ workspace SPEC)
Owner: karolkurek
Risk: low
Type: docs

## Cel

Zaktualizować **lokalne ścieżki dev** w runbookach i podstawowej dokumentacji operacyjnej po rebrandzie repo `homeserver-ansible` → `homeserver-services`.

## Zakres

### In scope

- `cd ~/repos/homeserver-ansible` → `homeserver-services` w `docs/runbooks/`
- `AGENTS.md` — poprawny GitHub repo
- `docs/skills/homeserver-ansible-deploy/SKILL.md` — treść (nazwa pliku bez zmiany — kompatybilność)

### Out of scope

- `/opt/homeserver-ansible-repo` na hostach G2/T630 (runtime path — osobna migracja infra)
- ADR historyczne (zachowują nazwę monorepo)
- `roles/trading/defaults` — ścieżki deploy na serwerze
- Zmiana user-agent w Python

## Definition of Done

- [x] Brak `repos/homeserver-ansible` w `docs/runbooks/`
- [x] AGENTS.md wskazuje `homeserver-services`
- [x] SKILL opisuje `homeserver-services`
