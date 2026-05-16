# SPEC-003C: Deploy wrapper scripts (T630 + G2)

Parent: SPEC-003
Status: done
Repo: homeserver-services
Owner: karolkurek
Risk: low
Type: tooling

## Cel

Dostarczyć brakujące skrypty wołane przez `scripts/ops-run.sh`: `deploy-g2.sh`, `deploy-t630-safe.sh` oraz `check-compose-image-pinning.sh` dla preflight.

## Kontekst

- Po SPEC-003B `playbooks/g2.yml` istnieje, ale `ops-run.sh deploy-g2` padał na brak skryptu.
- `deploy-t630-safe.sh` również brakował.
- `preflight` wołał nieistniejący `check-compose-image-pinning.sh`.

## Zakres

- [x] `scripts/deploy-g2.sh` — wzorzec z homeserver-core, playbook `playbooks/g2.yml`
- [x] `scripts/deploy-t630-safe.sh` — ten sam wzorzec, `playbooks/t630.yml`
- [x] `scripts/check-compose-image-pinning.sh` — szablony trading compose
- [x] Bez faktycznego deploy w testach (tylko `--help`, preflight, check playbooków)

## Out of scope

- Deploy na hostach w ramach tego SPEC
- EPIC-002 multi-repo orchestration w workspace

## Test plan (wykonany)

1. `deploy-g2.sh --help` / `deploy-t630-safe.sh --help` → 0
2. `scripts/ops-run.sh preflight` → 0
3. `check_playbooks.sh --syntax-check` → 0

## Na później

- EPIC-002: pełny deploy T630/G2 z workspace (core → life → services)
