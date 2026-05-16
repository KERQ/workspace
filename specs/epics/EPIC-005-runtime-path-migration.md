# EPIC-005: Migracja runtime path na hostach (G2)

Status: draft
Owner: karolkurek
Risk: high
Repos: homeserver-core, homeserver-services, workspace (docs/contracts)

## Cel

Ustawić kanoniczną ścieżkę runtime na **G2** na `/opt/homeserver-services`, konsolidując obecny aktywny layout (`homeserver-ansible-repo`) oraz osobny katalog Infisical (`homeserver-ansible/infisical`), z możliwością rollbacku.

## Decyzja nazewnicza

**Docelowy root:** `/opt/homeserver-services` (bez sufiksu `-repo`) — zgodność z nazwą repo Git `homeserver-services`.

Podkatalog `g2-config/` **bez zmiany nazwy**.

## Kontekst

- SPEC-004: lokalne ścieżki dev → `~/repos/homeserver-services`.
- Ansible w repo nadal hardcoded `/opt/homeserver-ansible-repo` i `/opt/homeserver-ansible`.
- Pełna zmiana wymaga **homeserver-core** (stack + infisical) i **homeserver-services** (trading, openclaw, plane).

## Audyt SSH (2026-05-16)

### T630 (`t630@192.168.1.20`)

| Ścieżka | Stan |
|---------|------|
| `/opt/homeserver-ansible` | **brak** |
| `/opt/homeserver-ansible-repo` | **brak** |
| `/opt/life-platform-t630/t630-config/` | **istnieje** — smart home (kanon life-platform) |
| `/opt/openclaw-control-plane/` | **istnieje** — osobny checkout |

**Wniosek:** EPIC-005 **nie obejmuje T630** dla ścieżek `homeserver-ansible*`.

### G2 (`g2@192.168.1.19`)

Dwa **osobne** katalogi (nie symlinki):

| Ścieżka | Zawartość | Produkcja |
|---------|-----------|-----------|
| `/opt/homeserver-ansible-repo` | `g2-config/` (pełny: minio, airflow, grafana, jupyter, plane, …), `scripts/trading/` | **tak** — Docker: airflow, litellm, minio → `...-repo/g2-config/...` |
| `/opt/homeserver-ansible` | `g2-config/` **stary** (mniejszy zestaw usług), `infisical/` osobno | **Infisical** → `working_dir` = `/opt/homeserver-ansible/infisical`; stary `g2-config` prawdopodobnie nieużywany |

Docelowy layout G2:

```text
/opt/homeserver-services/
├── g2-config/       ← z ...-ansible-repo
├── scripts/trading/
└── infisical/        ← z /opt/homeserver-ansible/infisical
```

## Docelowa zmienna Ansible

```yaml
homeserver_runtime_root: /opt/homeserver-services
```

- `homeserver-core`: `homeserver-stack`, `infisical_install_path`, szablony CLI
- `homeserver-services`: `trading`, `openclaw`, `plane`, skrypty

Kontrakt: [`contracts/storage/runtime-paths.yml`](../../contracts/storage/runtime-paths.yml)

## Fazy wdrożenia

### Faza 1 — Refactor Ansible (low risk, bez hostów)

**Cel:** `{{ homeserver_runtime_root }}` w kodzie; domyślna wartość **nadal stara** (`/opt/homeserver-ansible-repo`) do momentu Fazy 3.

Osobna zmienna dla Infisical w core (Faza 1b lub część 005A):

```yaml
homeserver_infisical_path: /opt/homeserver-ansible/infisical  # do Fazy 2
```

**Child SPEC:** `SPEC-005A-ansible-runtime-variable`

---

### Faza 2 — Migracja na G2 (medium/high, maintenance)

**Tylko host G2.** Sekwencja (runbook):

1. Backup: `rsync` obu drzew `/opt/homeserver-ansible-repo` i `/opt/homeserver-ansible`.
2. Utworzyć `/opt/homeserver-services/`:
   - `rsync` `...-ansible-repo/` → `/opt/homeserver-services/`
   - `rsync` `.../homeserver-ansible/infisical/` → `/opt/homeserver-services/infisical/`
3. Symlinki wsteczne (okno przejściowe):
   - `/opt/homeserver-ansible-repo` → `homeserver-services`
   - `/opt/homeserver-ansible/infisical` → `homeserver-services/infisical` (lub cały `/opt/homeserver-ansible` → TBD)
4. Restart Infisical + smoke trading/Airflow/LiteLLM.
5. Po weryfikacji: archiwum/usunięcie starego `/opt/homeserver-ansible/g2-config` (stale).

**Child SPEC:** `SPEC-005B-host-path-migration-g2`

**Wymaga:** `APPROVE_DEPLOY=yes`, okno maintenance.

**Anulowane:** ~~SPEC-005C-host-path-migration-t630~~ — brak ścieżek na T630.

---

### Faza 3 — Ansible → nowa ścieżka (high risk)

**Cel:** `homeserver_runtime_root: /opt/homeserver-services`, `infisical` pod nowym rootem.

Deploy warstwami na G2 (`contracts/deploy/g2-deploy-order.yml`):

1. `homeserver-core`
2. `homeserver-services`

**Child SPEC:** `SPEC-005D-deploy-new-runtime-path`

---

### Faza 4 — Cleanup

- Usunąć symlinki wsteczne
- Zaktualizować runbooki SSH (`/opt/homeserver-ansible-repo` → `/opt/homeserver-services`)
- Usunąć puste `/opt/homeserver-ansible`, `/opt/homeserver-ansible-repo` po weryfikacji

**Child SPEC:** `SPEC-005E-runtime-path-cleanup`

---

## Repo impact matrix

| Repo | Faza 1–4 |
|------|----------|
| workspace | ADR, contract, runbook G2 |
| homeserver-core | vars, infisical path, homeserver-stack |
| homeserver-services | vars, trading, openclaw, plane, skrypty |
| life-platform | **out of scope** (`/opt/life-platform-t630` osobno) |

## Global Definition of Done

- [ ] G2: Docker stacki działają z `/opt/homeserver-services/...`
- [ ] Brak hardcoded `/opt/homeserver-ansible-repo` w Ansible (poza ADR)
- [ ] Infisical pod `/opt/homeserver-services/infisical`
- [ ] Stary `/opt/homeserver-ansible/g2-config` usunięty lub zarchiwizowany
- [ ] T630 bez regresji (life-platform, openclaw-control-plane nietknięte)
- [ ] ADR accepted

## Approval gates

| Gate | Wymaganie |
|------|-----------|
| Faza 1 | review PR |
| Faza 2–3 G2 | `APPROVE_DEPLOY=yes` + maintenance |
| EPIC done | ADR + smoke G2 |

## Child SPECs

| SPEC | Faza | Status |
|------|------|--------|
| SPEC-005A-ansible-runtime-variable | 1 | done |
| SPEC-005B-host-path-migration-g2 | 2 | planned |
| ~~SPEC-005C-host-path-migration-t630~~ | — | **cancelled** (brak ścieżek na T630) |
| SPEC-005D-deploy-new-runtime-path | 3 | planned |
| SPEC-005E-runtime-path-cleanup | 4 | planned |

## Następny krok

Zatwierdzić EPIC → **SPEC-005A** (zmienne Ansible, stare wartości domyślne, bez deployu).
