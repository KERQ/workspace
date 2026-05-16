# SPEC-005A: Zmienna Ansible `homeserver_runtime_root`

Parent: [EPIC-005](epics/EPIC-005-runtime-path-migration.md)
Status: done
Repos: homeserver-core, homeserver-services, workspace
Owner: karolkurek
Risk: low
Type: refactor

## Cel

Wprowadzić `{{ homeserver_runtime_root }}` i powiązane zmienne w Ansible; **domyślne wartości bez zmiany** na hostach (Faza 1 EPIC-005).

## Zmienne (kontrakt)

| Zmienna | Faza 1 (domyślna) | Docelowo (Faza 3) |
|---------|-------------------|-------------------|
| `homeserver_runtime_root` | `/opt/homeserver-ansible-repo` | `/opt/homeserver-services` |
| `homeserver_g2_config_dir` | `{{ homeserver_runtime_root }}/g2-config` | (derived) |
| `homeserver_infisical_path` | `/opt/homeserver-ansible/infisical` | `/opt/homeserver-services/infisical` |
| `homeserver_legacy_g2_config_dir` | `/opt/homeserver-ansible/g2-config` | (usunąć po migracji) |

Źródło: `inventory/group_vars/all.yml` w obu repo Ansible.

## Zakres

### In scope

- `homeserver-core`: `homeserver-stack`, `infisical`, szablony CLI, `docker-compose` mount (replace po copy)
- `homeserver-services`: `trading`, `plane`, `openclaw`, `jupyter.yml`, smoke playbook
- `scripts/trading/smoke.sh`: env `HOMESERVER_RUNTIME_ROOT`
- Syntax-check przez workspace `deploy/scripts/deploy-g2-full.sh`

### Out of scope

- ADR, runbooki SSH (Faza 4)
- Deploy na G2 (`APPROVE_DEPLOY`)
- Zmiana wartości domyślnych na `/opt/homeserver-services`
- `backup-ha.sh.j2` (ścieżki T630 life-platform — osobny kontrakt)

## Definition of Done

- [x] `inventory/group_vars/all.yml` w core + services
- [x] Brak hardcoded `/opt/homeserver-ansible-repo` w rolach Ansible (poza komentarzami / replace regexp)
- [x] `ansible-playbook --syntax-check` G2 playbooks OK
- [x] EPIC-005 child SPEC-005A → done

## Test plan

```bash
cd ~/repos/workspace
./deploy/scripts/deploy-g2-full.sh
./scripts/checks/ansible-playbooks/check_playbooks.sh  # jeśli obejmuje oba repo
```
