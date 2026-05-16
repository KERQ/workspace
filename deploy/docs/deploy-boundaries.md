# Deploy boundaries

Granice odpowiedzialności warstw i kolejność pełnego deployu. Kanon: [`contracts/deploy/`](../../contracts/deploy/).

## T630 — kolejność (mandatory)

| Krok | Repo | Working dir | Playbook |
|------|------|-------------|----------|
| 1 | homeserver-core | `.` | `playbooks/t630.yml` |
| 2 | life-platform | `domains/home/ansible` | `playbooks/t630.yml` |
| 3 | homeserver-services | `.` | `playbooks/t630.yml` |

Reguły:

- **core** przed **life** i **services**
- Sekrety per repo — nie mieszaj `host_vars` między warstwami

## G2 — kolejność

| Krok | Repo | Playbook |
|------|------|----------|
| 1 | homeserver-core | `playbooks/g2.yml` |
| 2 | homeserver-services | `playbooks/g2.yml` |

**life-platform** nie deployuje na G2 domyślnie.

## Co wolno z workspace

| Akcja | Dozwolone |
|-------|-----------|
| `deploy/scripts/*-full.sh` bez `--apply` | syntax-check — tak |
| `--apply` bez `APPROVE_DEPLOY=yes` | nie |
| Agent bez approval | tylko syntax-check |
| Edycja playbooków w repo domenowych | osobny SPEC |

## Powiązane wrappery w repo

- `homeserver-services/scripts/deploy-t630-safe.sh` — tylko warstwa services na T630
- `homeserver-services/scripts/deploy-g2.sh` — tylko warstwa services na G2
- `homeserver-core/scripts/deploy-g2.sh` — warstwa core na G2

Pełny stack multi-repo → skrypty w `deploy/scripts/` tego workspace.
