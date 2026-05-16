# EPIC-005: Migracja runtime path na hostach

Status: draft
Owner: karolkurek
Risk: high
Repos: homeserver-core, homeserver-services, workspace (docs/contracts)

## Cel

Zmienić kanoniczną ścieżkę runtime na hostach z `/opt/homeserver-ansible-repo` na `/opt/homeserver-services-repo`, z zachowaniem działania stacków G2/T630 i możliwości rollbacku.

## Kontekst

- Repo Git nazywa się `homeserver-services` (i `homeserver-core` dla warstwy infra).
- Na hostach katalog `/opt/homeserver-ansible-repo` pochodzi z monorepo — nadal używany przez Ansible, Docker Compose, OpenClaw, runbooki operacyjne.
- SPEC-004 naprawił tylko **lokalne** ścieżki dev (`~/repos/...`).
- Pełna zmiana wymaga koordynacji **core + services + deploy na hostach**.

## Stan obecny (audyt 2026-05-16)

| Obszar | Pliki z `/opt/homeserver-ansible-repo` (orientacyjnie) |
|--------|--------------------------------------------------------|
| `homeserver-core` | ~21 trafień — gł. `roles/homeserver-stack/` |
| `homeserver-services` | ~38 plików — `roles/trading/defaults`, `openclaw`, `plane`, skrypty, runbooki |
| Wyjątki | `/opt/homeserver-ansible` (bez `-repo`) w starych ADR/template — do weryfikacji |

**Nie zmieniamy w tej migracji:** nazwy podkatalogu `g2-config/` (bundle konfiguracji).

## Docelowa zmienna Ansible

```yaml
# group_vars/all.yml (per repo) lub wspólny kontrakt workspace
homeserver_runtime_root: /opt/homeserver-services-repo
```

Wszystkie hardcoded `/opt/homeserver-ansible-repo` → `{{ homeserver_runtime_root }}`.

Kontrakt workspace (nowy lub rozszerzenie): `contracts/storage/runtime-paths.yml` — dokumentacja ścieżek bez sekretów.

## Fazy wdrożenia

### Faza 1 — Refactor bez zmiany zachowania (low risk)

**Cel:** Jedna zmienna, nadal stara wartość domyślna.

| Repo | Zakres |
|------|--------|
| homeserver-core | `homeserver-stack`, group_vars |
| homeserver-services | `trading`, `openclaw`, `plane`, skrypty z defaultami |
| workspace | ADR draft, `contracts/storage/runtime-paths.yml` |

**Test:** `ansible-playbook --syntax-check`, `deploy/*/full.sh` (syntax), brak deploy apply.

**Child SPEC:** `SPEC-005A-ansible-runtime-variable`

---

### Faza 2 — Przygotowanie hostów (medium risk, maintenance)

**Cel:** Na G2 i T630 przygotować nową ścieżkę bez przestoju lub z krótkim oknem.

Proponowana sekwencja (do zatwierdzenia w runbooku):

1. Maintenance: zatrzymać lub wstrzymać krytyczne DAG (G2) / OpenClaw gateway (T630) — według runbooka.
2. `rsync -a /opt/homeserver-ansible-repo/ /opt/homeserver-services-repo/` (lub `mv` jeśli dysk ten sam).
3. Symlink wsteczny: `/opt/homeserver-ansible-repo` → `homeserver-services-repo` (okno przejściowe).
4. Smoke: Airflow, MinIO, OpenClaw, LiteLLM — read-only checki.

**Child SPEC:** `SPEC-005B-host-path-migration-g2`, `SPEC-005C-host-path-migration-t630`

**Wymaga:** `APPROVE_DEPLOY=yes`, runbook rollback, backup ścieżki.

---

### Faza 3 — Ansible na nową ścieżkę (high risk)

**Cel:** `homeserver_runtime_root: /opt/homeserver-services-repo`, deploy warstwami.

Kolejność (zgodna z `contracts/deploy/`):

1. `homeserver-core` → G2 (i T630 jeśli dotyczy stacku)
2. `homeserver-services` → G2 / T630

**Test po każdej warstwie:** smoke scripts, health, `scripts/trading/smoke.sh` na G2.

**Child SPEC:** `SPEC-005D-deploy-new-runtime-path`

---

### Faza 4 — Cleanup (medium risk)

**Cel:** Usunąć symlink wsteczny, zaktualizować runbooki/ADR operacyjne, stare odniesienia.

- Runbooki: zamienić SSH ścieżki na nowy root
- Usunąć symlink `/opt/homeserver-ansible-repo` gdy nic nie korzysta
- Opcjonalnie: archiwum starego katalogu → backup

**Child SPEC:** `SPEC-005E-runtime-path-cleanup`

---

## Repo impact matrix

| Repo | Faza 1 | Faza 2 | Faza 3 | Faza 4 |
|------|--------|--------|--------|--------|
| workspace | ADR, contract | runbook | — | docs |
| homeserver-core | vars + roles | host ops | deploy | docs |
| homeserver-services | vars + roles | host ops | deploy | docs |
| life-platform | — | — | — | — |

## Global Definition of Done

- [ ] Brak hardcoded `/opt/homeserver-ansible-repo` w Ansible (poza ADR historycznymi)
- [ ] Hosty G2/T630 używają `/opt/homeserver-services-repo` jako kanon
- [ ] Smoke testy przechodzą
- [ ] Rollback przetestowany lub udokumentowany
- [ ] ADR `accepted` w workspace

## Global test plan

1. Faza 1: syntax-check wszystkich playbooków (workspace deploy scripts).
2. Faza 2: `mc`, `airflow dags list`, `curl` OpenClaw gateway — bez regresji.
3. Faza 3: pełny smoke trading + OpenClaw po deploy.
4. Faza 4: `grep -r homeserver-ansible-repo` w repo (poza ADR) → 0 w kodzie operacyjnym.

## Rollback

| Faza | Rollback |
|------|----------|
| 1 | revert PR Ansible |
| 2 | usuń nowy katalog / symlink, przywróć stary layout z backupu |
| 3 | revert zmiany vars + redeploy ze starą ścieżką |
| 4 | przywróć symlink jeśli usunięty za wcześnie |

## Approval gates

| Gate | Wymaganie |
|------|-----------|
| Faza 1 merge | review PR |
| Faza 2+ na hostach | explicit `APPROVE_DEPLOY=yes` + okno maintenance |
| Faza 3 apply | deploy per warstwa + smoke |
| EPIC done | ADR accepted |

## Child SPECs (plan)

| SPEC | Faza | Status |
|------|------|--------|
| SPEC-005A-ansible-runtime-variable | 1 | planned |
| SPEC-005B-host-path-migration-g2 | 2 | planned |
| SPEC-005C-host-path-migration-t630 | 2 | planned |
| SPEC-005D-deploy-new-runtime-path | 3 | planned |
| SPEC-005E-runtime-path-cleanup | 4 | planned |

## Następny krok

Zatwierdzić EPIC → rozpocząć **SPEC-005A** (tylko refactor zmiennej, stara wartość, bez deployu na hostach).
