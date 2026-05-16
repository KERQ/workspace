# SPEC-005D: Ansible — docelowe ścieżki runtime + deploy G2

Parent: [EPIC-005](epics/EPIC-005-runtime-path-migration.md)  
Status: done  
Repos: homeserver-core, homeserver-services, workspace  
Host: g2@192.168.1.19  
Owner: karolkurek  
Risk: high  
Type: config + deploy

## Wymagania wstępne

- [x] [SPEC-005B](SPEC-005B-host-path-migration-g2.md) — cutover done
- [x] Kanon na hoście: `/opt/homeserver-services` (+ symlinki wsteczne)
- [x] Akceptacja tego SPEC → implementacja (2026-05-16)

## Cel

Ustawić w Ansible **docelowe** wartości ścieżek (bez polegania na symlinkach w logice deployu) i wykonać **apply** playbooków G2, tak aby kolejne uruchomienia Ansible operowały wprost na `/opt/homeserver-services`.

Po 005D host nadal może mieć symlinki wsteczne (do usunięcia w **SPEC-005E**).

## Stan hosta (wejście)

| Ścieżka | Stan |
|---------|------|
| `/opt/homeserver-services` | Kanon (dane) |
| `/opt/homeserver-ansible-repo` | → symlink do `homeserver-services` |
| `/opt/homeserver-ansible/infisical` | → symlink do `homeserver-services/infisical` |
| `.bak-*` cutover | Zachować do 005E |

## Docelowe wartości zmiennych

| Zmienna | Obecnie (`all.yml`) | Po 005D (G2) |
|---------|---------------------|--------------|
| `homeserver_runtime_root` | `/opt/homeserver-ansible-repo` | `/opt/homeserver-services` |
| `homeserver_g2_config_dir` | derived | `{{ homeserver_runtime_root }}/g2-config` |
| `homeserver_infisical_path` | `/opt/homeserver-ansible/infisical` | `/opt/homeserver-services/infisical` |
| `homeserver_legacy_g2_config_dir` | `/opt/homeserver-ansible/g2-config` | **usunąć użycie** lub = `homeserver_g2_config_dir` |

**Ważne:** nadpisać ścieżki w `inventory/group_vars/g2_servers.yml` (oba repo), **nie** w `all.yml` — żeby playbooki T630 nie dostały ścieżek G2.

### Pliki do edycji

| Repo | Plik | Zmiana |
|------|------|--------|
| homeserver-core | `inventory/group_vars/g2_servers.yml` | docelowe `homeserver_*` |
| homeserver-services | `inventory/group_vars/g2_servers.yml` | **utworzyć** — ten sam kontrakt |
| homeserver-core | `roles/homeserver-stack/templates/flockmem-cli.sh.j2` | `homeserver_g2_config_dir` zamiast `legacy` |
| homeserver-core | `roles/homeserver-stack/templates/ops-auditlog-cli.sh.j2` | j.w. |
| homeserver-core | `roles/homeserver-stack/tasks/main.yml` | `replace` regexp: obsłużyć obie ścieżki lub tylko kanon |
| homeserver-core | `roles/homeserver-stack/files/g2-config/docker-compose.yml` | mount Samba → `/opt/homeserver-services` (opcjonalnie; replace i tak naprawia) |
| homeserver-services | `scripts/trading/smoke.sh` | domyślny `HOMESERVER_RUNTIME_ROOT` → kanon |
| workspace | `contracts/storage/runtime-paths.yml` | `ansible_phase3_active: true` |

### Bez zmiany w 005D

- Runbooki SSH, ADR (`SPEC-005E`)
- Usuwanie symlinków / `.bak-*`
- T630, life-platform
- `backup-ha.sh.j2` (ścieżki T630)

## Deploy

Kolejność: [`contracts/deploy/g2-deploy-order.yml`](../contracts/deploy/g2-deploy-order.yml)

```bash
cd ~/repos/workspace

# 1. Syntax-check (bez hosta)
./deploy/scripts/deploy-g2-full.sh

# 2. Apply (wymaga jawnej zgody)
APPROVE_DEPLOY=yes ./deploy/scripts/deploy-g2-full.sh --apply
```

Warstwy:

1. `homeserver-core` → `playbooks/g2.yml`
2. `homeserver-services` → `playbooks/g2.yml`

**Oczekiwany efekt:** role kopiują/szablonują pod `{{ homeserver_runtime_root }}` = `/opt/homeserver-services` (to samo miejsce co dziś przez symlink, ale Ansible „widzi” kanon).

**Ryzyko:** `docker compose up` / recreate kontenerów, krótkie przerwy w usługach — okno podobne do zwykłego deployu G2.

## Weryfikacja po deploy

```bash
# Na G2
readlink -f /opt/homeserver-ansible-repo   # nadal → homeserver-services (do 005E)
docker inspect caddy --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}'
# Oczekiwane: .../opt/homeserver-services/g2-config/docker-compose.yml (po recreate)

ssh g2@192.168.1.19 'HOMESERVER_RUNTIME_ROOT=/opt/homeserver-services bash /opt/homeserver-services/scripts/trading/smoke.sh'

cd ~/repos/workspace
./deploy/scripts/migrate-g2-runtime-path.sh smoke
```

Kryteria:

- [ ] `ansible-playbook --syntax-check` OK (oba repo)
- [ ] Deploy apply bez błędów fatal
- [ ] LiteLLM, Airflow, MinIO, Infisical — health OK
- [ ] Trading smoke ≥ poprzedni baseline (005B)
- [ ] Compose labels wskazują `homeserver-services` (nie tylko symlink `ansible-repo`)

## Rollback

1. Przywrócić stare wartości w `g2_servers.yml` (ścieżki legacy / symlink).
2. `APPROVE_DEPLOY=yes ./deploy/scripts/deploy-g2-full.sh --apply`
3. Symlinki z 005B nadal działają jako siatka bezpieczeństwa, dopóki nie usunięte w 005E.

Pełny rollback filesystem: `migrate-g2-runtime-path.sh rollback` (tylko jeśli deploy zepsuł layout — rzadkie).

## Definition of Done

- [x] `g2_servers.yml` w core + services z docelowymi ścieżkami
- [x] Szablony CLI używają `homeserver_g2_config_dir` (aktywny `.env`)
- [x] `deploy-g2-full.sh --apply` — core OK; services OK po fix Jupyter (2026-05-16)
- [x] Smoke G2 PASS (trading 13/13; LiteLLM health WARN — znany endpoint)
- [x] Kontrakt `runtime-paths.yml` zaktualizowany
- [x] EPIC-005: SPEC-005D → done

## Uwagi operacyjne (deploy)

- Pierwszy apply: błąd ścieżki Infisical (`playbook_dir/../g2-config`) — naprawione w `homeserver-core` (`infisical_compose_source_dir`)
- Services apply: fatal na brak `notebooks/` — naprawione (`jupyter.yml` skip gdy brak źródła)
- Compose labels na G2 wskazują `/opt/homeserver-services/...`

## Approval gates

| Gate | Wymaganie |
|------|-----------|
| Merge PR Ansible | review |
| Deploy G2 | `APPROVE_DEPLOY=yes` + komunikat „start 005D apply” |
| Zamknięcie SPEC | smoke PASS |

## Następny krok po 005D

**SPEC-005E** — cleanup: usunięcie symlinków, runbooki SSH, archiwum `.bak-*` i stale `homeserver-ansible/g2-config`.

---

**Start implementacji:** napisz „akceptuję SPEC-005D” lub „start 005D apply” (drugie = deploy na G2).
