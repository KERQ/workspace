# Deploy orchestration (workspace)

Jednopunktowe entrypointy dla pełnego deployu multi-repo. Kolejność warstw jest zapisana w skryptach i musi być zgodna z [`contracts/deploy/`](../contracts/deploy/).

## Zasady

- Deploy na hosty jest **manual_only**.
- **Domyślnie** skrypty wykonują tylko `ansible-playbook --syntax-check` (bez zmian na hostach).
- Faktyczny apply wymaga: `APPROVE_DEPLOY=yes` oraz flagi `--apply`.

## Wymagania

- Repozytoria domenowe pod symlinkami w workspace (`homeserver-core`, `life-platform`, `homeserver-services`).
- Lokalne `inventory/host_vars/*.yml` w każdym repo (gitignored) — skrypty ich nie tworzą.
- `ansible-playbook` w PATH.

## Pełny deploy

```bash
cd ~/repos/workspace

# T630 — syntax-check wszystkich warstw (domyślne)
./deploy/scripts/deploy-t630-full.sh

# T630 — apply (tylko po świadomej zgodzie)
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-t630-full.sh --apply

# G2
./deploy/scripts/deploy-g2-full.sh
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-g2-full.sh --apply
```

## Deploy granularny

| Skrypt | Warstwa |
|--------|---------|
| `deploy-t630-core.sh` | homeserver-core |
| `deploy-t630-life.sh` | life-platform |
| `deploy-t630-services.sh` | homeserver-services |
| `deploy-g2-core.sh` | homeserver-core |
| `deploy-g2-services.sh` | homeserver-services |

## Inventory (informacyjne)

[`inventory/hosts.yml`](inventory/hosts.yml) — mapa hostów bez sekretów. Ansible inventory per repo pozostaje w repo domenowych.

## Dokumentacja

- [`docs/deploy-boundaries.md`](docs/deploy-boundaries.md)
- Kontrakty: [`contracts/deploy/`](../contracts/deploy/)

## Checki

```bash
./scripts/checks/deploy/check_deploy_contract.sh
```
