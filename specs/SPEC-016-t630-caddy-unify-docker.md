# SPEC-016: T630 — ujednolicenie Caddy (jeden reverse proxy, Docker)

Parent: [SPEC-015](SPEC-015-t630-g2-service-dashboard.md)
Status: done
Repo: life-platform (+ workspace: runbook/ADR)
Owner: karolkurek
Risk: medium
Type: infra
Blokuje: [EPIC-006](epics/EPIC-006-forgejo-mvp.md) (SPEC-006B — vhost `git.*` na T630)

## Cel

Na T630 ma działać **jeden** reverse proxy na porcie **80**: kontener **Docker Caddy** ze stacku `life-platform`. Hostowy `caddy.service` (systemd) ma zostać wyłączony, aby usunąć konflikt `:80 address already in use` i przygotować stabilną bazę pod Forgejo (EPIC-006).

## Decyzja

| Opcja | Werdykt |
|-------|---------|
| **A: systemd `caddy.service`** | Odrzucone — duplikat poza compose/Ansible `life-platform` |
| **B: Docker Caddy (`life-platform`)** | **Wybrane** — źródło prawdy w repo, zgodne z `docker-compose` T630 |

**Właściciel Caddyfile na T630:** `life-platform/domains/home/configs/caddy/Caddyfile` (deploy na host jako `/opt/life-platform-t630/t630-config/caddy/`).

**Konsekwencja dla EPIC-006:** `SPEC-006B` nie stawia osobnego Caddy na T630 — dodaje vhost Forgejo do **tego samego** pliku w `life-platform` (lub przez wspólny fragment włączany z Ansible).

## Kontekst

- [SPEC-015](SPEC-015-t630-g2-service-dashboard.md) — audyt wykazał:
  - `systemd caddy.service` active, PID na `*:80`, config `/etc/caddy/Caddyfile`
  - kontener `caddy` w stanie `Restarting`, błąd bind `:80`
  - compose `life-platform`: `network_mode: host` dla kontenera `caddy`
- [Dashboard](../docs/runbooks/t630-g2-service-dashboard.md)
- Obecny `Caddyfile` w repo zawiera trasy: HA redirect, Zigbee, ClawSuite, OpenClaw — to ma zostać zachowane po przejściu na Docker.

## Zakres

### In scope

1. **Audyt różnic** między:
   - `/etc/caddy/Caddyfile` (host systemd),
   - `/opt/life-platform-t630/t630-config/caddy/Caddyfile` (deploy z repo).
2. **Wyłączenie** hostowego Caddy:
   - `systemctl disable --now caddy.service`
   - opcjonalnie `systemctl mask caddy.service` (jeśli pakiet/systemd wraca po update — do oceny).
3. **Uruchomienie** kontenera `caddy` ze stacku `life-platform`:
   - `docker compose up -d caddy` w katalogu stacku T630,
   - ewentualnie przez Ansible tag `caddy` w `playbooks/t630.yml`.
4. **Smoke test** tras z istniejącego `Caddyfile` (HA, Zigbee, ClawSuite, OpenClaw, root).
5. **Dokumentacja** właściciela ingress na T630 (runbook + krótki ADR lub sekcja w runbook).
6. **Aktualizacja EPIC-006** — `life-platform` dostaje rolę w `SPEC-006B` (vhost), nie osobny Caddy w `homeserver-core` na `:80`.

### Out of scope

- Wdrożenie Forgejo (SPEC-006A i dalsze).
- Zmiana modelu Caddy na G2 (tam Docker Caddy już działa).
- HTTPS/Tailscale Serve dla wszystkich usług — tylko naprawa `:80` i stabilizacja reverse proxy.
- Pełna refaktoryzacja `Caddyfile` (np. migracja redirectów HA na `reverse_proxy` zamiast `redir`).

## Pliki / obszary

### Read

- `life-platform/domains/home/configs/docker-compose.yml`
- `life-platform/domains/home/configs/caddy/Caddyfile`
- `life-platform/domains/home/ansible/roles/home-assistant/tasks/main.yml` (tag `caddy`)
- Host T630: `/etc/caddy/Caddyfile`, `systemctl status caddy`, `docker ps`, `ss -lntp`

### Write

- `life-platform` — tylko jeśli trzeba zsynchronizować `Caddyfile` po audycie (merge z hosta).
- `workspace/docs/runbooks/t630-caddy-unify.md` (nowy, krótki runbook operacyjny).
- `workspace/docs/adr/` — opcjonalny ADR „T630 ingress owner = life-platform Docker Caddy”.
- `workspace/specs/epics/EPIC-006-forgejo-mvp.md` — doprecyzowanie 006B.
- `workspace/BACKLOG.md` — link do SPEC-016.

### Forbidden

- Drugi proces nasłuchujący na `:80` po zakończeniu SPEC.
- Deploy Forgejo, zmiany w `homeserver-services` poza uzgodnionym vhost snippet (to 006B).
- Automatyczne `systemctl disable` bez smoke testu planu rollback.

## Do zrobienia

- [x] Porównać `Caddyfile` host vs repo (`diff`); pliki zgodne.
- [x] Backup obu plików na T630 (`/tmp/Caddyfile.*.bak.20260517`).
- [x] Wyłączyć `caddy.service` na T630.
- [x] Uruchomić kontener `caddy` (recreate po stop + `docker compose up -d`).
- [x] Smoke test tras (tabela w sekcji Test plan).
- [x] Zaktualizować runbook operacyjny.
- [x] EPIC-006 już wskazuje `life-platform` dla 006B.
- [x] Worklog: [SPEC-016-2026-05-17](../docs/worklog/OPS/SPEC-016-2026-05-17-t630-caddy-unify.md).

## Definition of Ready

- [ ] SPEC-015 done
- [ ] Approval na operację na T630 (disable systemd + recreate docker caddy)
- [ ] Znany czas okna (krótka przerwa na `:80` możliwa)

## Definition of Done

- [ ] Tylko **jeden** listener na `*:80` (kontener Docker Caddy lub jego proces w host network).
- [ ] `docker ps` → `caddy` **Up**, nie `Restarting`.
- [ ] `systemctl is-enabled caddy` → **disabled** (lub masked).
- [ ] Smoke test z sekcji Test plan — wszystkie wymagane trasy OK lub jawne wyjątki w worklog.
- [ ] Runbook `t630-caddy-unify.md` opublikowany.
- [ ] EPIC-006 odblokowany dla SPEC-006B (vhost Forgejo).

## Test plan

### Przed zmianą (baseline)

```bash
ssh t630@192.168.1.20 '
  systemctl is-active caddy
  sudo ss -lntp "sport = :80"
  docker ps --filter name=caddy
  diff -u /etc/caddy/Caddyfile /opt/life-platform-t630/t630-config/caddy/Caddyfile || true
'
```

### Po wyłączeniu systemd i starcie kontenera

```bash
ssh t630@192.168.1.20 '
  systemctl is-enabled caddy
  sudo ss -lntp "sport = :80"
  docker ps --filter name=caddy
  docker logs caddy --tail 20
'
```

### Smoke HTTP (z hosta T630 lub LAN)

| Trasa | Oczekiwane | Komenda |
|-------|------------|---------|
| Root | `200` lub `404` z file_server (nie błąd bind) | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1/` |
| `/HA` | redirect `302` → `:8123` | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1/HA` |
| `/zigbee2mqtt` | redirect `302` → `:8099` | j.w. |
| `/clawsuite/` | `200` (lub redirect w aplikacji) | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1/clawsuite/` |
| `/openclaw/` | `200` / proxy do gateway | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1/openclaw/` |

Home Assistant i Zigbee nadal bezpośrednio:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8123/
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8099/
```

### Kryterium sukcesu

```text
Brak "address already in use" w docker logs caddy.
Jedna usługa reverse proxy na :80.
Istniejące trasy z Caddyfile w repo działają jak przed incydentem (w granicy redirect/proxy).
```

## Rollback

| Krok | Cofnięcie |
|------|-----------|
| Po disable systemd | `systemctl unmask caddy && systemctl enable --now caddy.service` |
| Po zmianie Caddyfile w repo | `git revert` w `life-platform` + redeploy |
| Kontener nie wstaje | `docker compose stop caddy`; przywrócić systemd tymczasowo |

**Uwaga:** rollback do dwóch Caddy jednocześnie **nie** jest celem — tylko awaryjnie na czas diagnostyki.

## Approval gates

| Gate | Wymagane |
|------|----------|
| Start implementacji | karolkurek |
| `systemctl disable caddy` na T630 | explicit approval |
| Deploy Ansible / `docker compose` recreate caddy | `APPROVE_DEPLOY=yes` jeśli przez playbook |

## Wpływ na inne SPECs

| SPEC / EPIC | Zmiana |
|-------------|--------|
| EPIC-006 | `SPEC-006B` edytuje `life-platform/.../caddy/Caddyfile`, nie tworzy drugiego Caddy |
| EPIC-007 | OpenClaw `/v1` może korzystać z istniejących tras `/v1*` w Caddyfile |
| EPIC-014 | bez zmiany |

## Work log

- [2026-05-17 — Caddy unify](../docs/worklog/OPS/SPEC-016-2026-05-17-t630-caddy-unify.md)

## Prompt plan

1. Przeczytaj SPEC-015 i dashboard T630/G2.
2. Wykonaj diff Caddyfile host vs repo.
3. Zaplanuj okno; poproś o approval przed disable systemd.
4. Disable systemd → start docker caddy → smoke.
5. Zaktualizuj runbook, worklog, EPIC-006.
6. Nie wdrażaj Forgejo w tym SPEC.

## Na później

- Tailscale HTTPS / hostnames zamiast surowego `:80` (osobny SPEC).
- Konsolidacja dokumentacji „kto dodaje vhost na T630” w `contracts/services/`.
