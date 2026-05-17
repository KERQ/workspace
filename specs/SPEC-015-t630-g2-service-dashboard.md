# SPEC-015: T630/G2 — audyt usług i one-pager operacyjny (nie aplikacja web)

Parent: BACKLOG
Status: done
Repo: workspace
Owner: karolkurek
Risk: low
Type: docs

## Cel

Przygotować jedną stronę operacyjną pokazującą zainstalowane/działające usługi na T630 i G2, linki do web UI (jeśli dotyczy), porty oraz bieżący status. Wynik ma być bazą do kolejnego SPEC/fix dla konfliktu Caddy na T630.

## Kontekst

- Backlog: „Przegląd zainstalowanych/działając usług i aplikacji na T630 i G2...”.
- SPEC-014A wykrył problem: kontener `caddy` na T630 restartuje się przez konflikt portu `:80`.
- Przed Forgejo (EPIC-006) trzeba znać aktualnych właścicieli portów, szczególnie `80`, `443`, `3000`, `3001`, `3002`, `2222`.

## Zakres

### In scope

- Read-only audyt T630 i G2: `docker ps`, `ss -lntp`, `systemctl --failed`, wybrane HTTP smoke checks.
- One-pager: [`docs/runbooks/t630-g2-service-dashboard.md`](../docs/runbooks/t630-g2-service-dashboard.md).
- Worklog z wykonania: [`docs/worklog/OPS/SPEC-015-2026-05-17-t630-g2-service-dashboard.md`](../docs/worklog/OPS/SPEC-015-2026-05-17-t630-g2-service-dashboard.md).
- Wskazanie follow-up dla Caddy.

### Out of scope

- Restart, deploy lub naprawa Caddy.
- Zmiana konfiguracji portów.
- Tworzenie automatycznego dashboardu live.

## Pliki / obszary

### Read

- `contracts/services/ports.yml`
- `deploy/inventory/hosts.yml`
- Hosty: T630 (`192.168.1.20`), G2 (`192.168.1.19`) — tylko read-only komendy.

### Write

- `docs/runbooks/t630-g2-service-dashboard.md`
- `docs/worklog/OPS/SPEC-015-2026-05-17-t630-g2-service-dashboard.md`
- `BACKLOG.md`

### Forbidden

- Deploy/restart usług.
- Edycja konfiguracji hostów.
- Odczyt sekretów (`.env`, tokeny, klucze).

## Do zrobienia

- [x] Read-only audyt T630
- [x] Read-only audyt G2
- [x] HTTP smoke checks dla web UI
- [x] One-pager dashboard
- [x] Worklog
- [x] Follow-up dla Caddy

## Definition of Ready

- [x] Cel i zakres są jasne
- [x] Repo i ryzyko określone
- [x] Test plan zdefiniowany
- [x] Rollback opisany
- [x] Approval użytkownika na start implementacji

## Definition of Done

- [x] One-pager zawiera T630 i G2
- [x] One-pager pokazuje link/status dla usług webowych
- [x] Konflikt Caddy na T630 opisany jako osobny follow-up
- [x] Test plan wykonany
- [x] Worklog dodany

## Test plan

1. `ssh t630@192.168.1.20 'ss -lntp; docker ps; systemctl --failed'`
2. `ssh g2@192.168.1.19 'ss -lntp; docker ps; systemctl --failed'`
3. HTTP smoke checks przez `curl --max-time 3` na lokalnych portach.
4. Weryfikacja dokumentu przez linter Markdown/IDE.

## Test plan (wykonany)

| Host | Wynik |
|------|-------|
| T630 | Docker: większość usług up; `caddy` container restarting; systemd `caddy.service` active; failed systemd units: 0 |
| G2 | Docker: główne usługi up; failed systemd units: 0; `/mnt/seagate` ~21T free |
| HTTP smoke | T630/G2 web UI zwracają 2xx/3xx/404 zależnie od endpointu; brak timeoutów dla sprawdzanych lokalnych portów |

## Work log

- [2026-05-17 — service dashboard audit](../docs/worklog/OPS/SPEC-015-2026-05-17-t630-g2-service-dashboard.md)

## Rollback

Zmiana dokumentacyjna. Rollback: revert commit w workspace.

## Prompt plan

1. Czytaj `BACKLOG.md`, `contracts/services/ports.yml`, `deploy/inventory/hosts.yml`.
2. Zbierz read-only stan hostów.
3. Nie restartuj i nie deployuj.
4. Zapisz one-pager i worklog.
5. Wskaż osobny SPEC/fix dla Caddy.

## Na później

- [SPEC-016](SPEC-016-t630-caddy-unify-docker.md): ujednolicenie Caddy na T630 (Docker `life-platform`).
- **Dashboard web:** backlog — aplikacja WWW (osobny SPEC); ten dokument to tylko statyczny one-pager z audytu.
