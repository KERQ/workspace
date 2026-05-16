# EPIC-002: Deploy orchestration (multi-repo Ansible)

Status: done
Owner: karolkurek
Risk: medium
Repos: workspace (orchestration), read-only refs to core / life / services

## Cel

Ujednolicić UX pełnego deployu T630 i G2 z workspace — kolejność warstw z `contracts/deploy/`, bez scalania Ansible do jednego repo.

## Kontekst

- EPIC-001 + SPEC-003*: playbooki i wrappery w repo domenowych.
- Etap 1 planu AI-Native Workspace.

## In scope (zrealizowane)

- [x] `deploy/README.md`, `deploy/inventory/hosts.yml`, `deploy/docs/deploy-boundaries.md`
- [x] `deploy/lib/common.sh` — `APPROVE_DEPLOY` gate
- [x] Full: `deploy-t630-full.sh`, `deploy-g2-full.sh`
- [x] Granular: core / life / services per host
- [x] `scripts/checks/deploy/check_deploy_contract.sh`

## Out of scope (później)

- CI / Forgejo integration
- Automatyczny apply bez approval

## Child SPECs

| SPEC | Status | Opis |
|------|--------|------|
| SPEC-002A-deploy-skeleton | done | README, inventory, boundaries |
| SPEC-002B-full-deploy-scripts | done | full + granular scripts |
| SPEC-002C-deploy-contract-check | done | check_deploy_contract.sh |

## Global Definition of Done

- [x] Z workspace entrypoint T630 i G2 (full scripts)
- [x] Domyślnie syntax-check; `--apply` + `APPROVE_DEPLOY=yes`
- [x] Kolejność zgodna z contracts
- [x] Test: `deploy-t630-full.sh`, `deploy-g2-full.sh`, contract check

## Użycie

```bash
cd ~/repos/workspace
./deploy/scripts/deploy-t630-full.sh
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-g2-full.sh --apply  # tylko po świadomej zgodzie
./scripts/checks/deploy/check_deploy_contract.sh
```
