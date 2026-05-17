# SPEC-005E: Cleanup runtime path (G2) + dokumentacja

Parent: [EPIC-005](epics/EPIC-005-runtime-path-migration.md)  
Status: in_progress (E1 done — E2 host cleanup pending)  
Repos: workspace, homeserver-services (runbooki), homeserver-core (opcjonalnie `all.yml`)  
Host: g2@192.168.1.19  
Owner: karolkurek  
Risk: medium  
Type: cleanup + docs

## Wymagania wstępne

- [x] [SPEC-005D](SPEC-005D-deploy-new-runtime-path.md) — deploy OK, compose na `/opt/homeserver-services`
- [x] Smoke G2 PASS (trading 13/13)
- [x] Akceptacja tego SPEC → E1 implementacja (2026-05-16)

## Cel

Domknąć EPIC-005: usunąć **tymczasowe** artefakty migracji na G2, zaktualizować dokumentację operacyjną na kanoniczną ścieżkę, zamknąć kontrakt i ADR.

Po 005E na G2 zostaje wyłącznie **`/opt/homeserver-services`** (bez symlinków wstecznych i bez `.bak-*` cutover).

## Stan wejścia (G2)

| Element | Lokalizacja |
|---------|-------------|
| Kanon | `/opt/homeserver-services` |
| Symlink wsteczny repo | `/opt/homeserver-ansible-repo` → `homeserver-services` |
| Symlink Infisical | `/opt/homeserver-ansible/infisical` → `.../infisical` |
| Backup cutover | `/opt/homeserver-ansible-repo.bak-20260516-211434` |
| Backup infisical | `/opt/homeserver-ansible-infisical.bak-20260516-211434` |
| Stale (prawdopodobnie) | `/opt/homeserver-ansible/g2-config` (stary, nieużywany) |
| Seagate backup | `/mnt/seagate/backups/epic-005-g2-runtime-path/` |

**Warunek bezpieczeństwa:** Docker compose labels muszą wskazywać `homeserver-services` (nie tylko przez symlink). Zweryfikować w `preflight`.

## Zakres

### Faza E1 — Dokumentacja (low risk, bez hosta)

| Repo | Pliki | Zmiana |
|------|-------|--------|
| homeserver-services | `docs/runbooks/*.md` z SSH `homeserver-ansible-repo` | → `/opt/homeserver-services` |
| homeserver-services | `docs/agents/`, `AGENTS.md` (jeśli runtime SSH) | kanon G2 |
| homeserver-core | `inventory/group_vars/all.yml` | domyślne ścieżki = kanon (T630 i tak nie używa tych ścieżek) |
| homeserver-services | `inventory/group_vars/all.yml` | j.w. |
| workspace | `contracts/storage/runtime-paths.yml` | `g2_current` = target, `phase4_cleanup: done` |
| workspace | `docs/adr/` | ADR EPIC-005 accepted |
| workspace | `PROJEKT.md`, `PLAN.md` | status migracji |

**Nie zmieniać:** historyczne ADR w repo domenowych (nazwa monorepo `homeserver-ansible` w tytułach/data).

### Faza E2 — Cleanup hosta G2 (medium risk)

Sekwencja ([runbook](../docs/runbooks/g2-runtime-path-cleanup.md)):

1. `preflight` — brak compose na starych ścieżkach poza symlinkiem; smoke baseline
2. `archive-bak` — przenieść `.bak-*` na Seagate (nie usuwać od razu)
3. `remove-symlinks` — usunąć `/opt/homeserver-ansible-repo`, `/opt/homeserver-ansible/infisical` (tylko symlinki)
4. `remove-stale` — zarchiwizować/usunąć `/opt/homeserver-ansible/g2-config` jeśli puste/nieużywane
5. `smoke` — health + `scripts/trading/smoke.sh`

**Wymaga:** `APPROVE_DEPLOY=yes` dla kroków E2 modyfikujących `/opt`.

### Artefakty workspace

| Plik | Rola |
|------|------|
| `scripts/migration/g2-runtime-path-cleanup.sh` | Logika na G2 |
| `deploy/scripts/cleanup-g2-runtime-path.sh` | Wrapper SSH + approve |
| `docs/runbooks/g2-runtime-path-cleanup.md` | Procedura |

## Poza zakresem

- T630, life-platform, openclaw-control-plane
- Zmiana nazwy `g2-config/`
- Forgejo / OpenClaw

## Definition of Done

- [x] Runbooki operacyjne G2: komendy SSH → `/opt/homeserver-services` (ADR historyczne bez zmian)
- [ ] G2: brak symlinków `homeserver-ansible-repo` / `homeserver-ansible/infisical` (E2)
- [ ] `.bak-*` zarchiwizowane na Seagate, usunięte z `/opt` (E2)
- [ ] Stale `homeserver-ansible/g2-config` usunięte lub w archiwum (E2)
- [x] `all.yml` w obu repo Ansible — domyślne ścieżki = kanon
- [ ] Smoke PASS po cleanup (E2)
- [x] ADR workspace `accepted`
- [ ] EPIC-005 → **done** (po E2)

## Test plan

```bash
cd ~/repos/workspace
./deploy/scripts/cleanup-g2-runtime-path.sh preflight
# po akceptacji:
APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh archive-bak --apply
APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh remove-symlinks --apply
APPROVE_DEPLOY=yes ./deploy/scripts/cleanup-g2-runtime-path.sh remove-stale --apply
./deploy/scripts/cleanup-g2-runtime-path.sh smoke
```

Weryfikacja końcowa:

```bash
ssh g2@192.168.1.19 'test ! -e /opt/homeserver-ansible-repo; ls -la /opt/homeserver-services'
rg '/opt/homeserver-ansible-repo' homeserver-services/docs/runbooks/  # 0 w komendach operacyjnych
```

## Rollback

| Krok | Rollback |
|------|----------|
| remove-symlinks | Przywrócić symlinki z [005B runbook](g2-runtime-path-migration.md) + dane z archiwum `.bak-*` |
| remove-stale | Przywróć z archiwum Seagate |
| docs | revert PR |

Pełny rollback filesystem: [migrate-g2-runtime-path.sh rollback](g2-runtime-path-migration.md) tylko jeśli uszkodzono layout.

## Approval gates

| Gate | Wymaganie |
|------|-----------|
| E1 docs | review PR |
| E2 host | `APPROVE_DEPLOY=yes` + smoke PASS |
| EPIC done | ADR accepted |

## Następny krok

Napisz **„akceptuję SPEC-005E”** (docs + skrypt) lub **„start 005E apply”** (z cleanup na G2).
