# Contracts — umowy między repo

## Definicja

`contracts/` odpowiada na pytanie:

**Co musi być prawdą, żeby kilka repo mogło ze sobą bezpiecznie współpracować?**

To nie jest implementacja, backlog ani miejsce na sekrety.

## Typy kontraktów (pełna lista docelowa)

| Typ | Opis |
|-----|------|
| `deploy/` | Kolejność i granice deployu |
| `ansible/` | Ownership ról i dozwolone hosty |
| `services/` | Porty, exposure, auth |
| `secrets/` | Scopes i polityka (bez wartości) |
| `repos/` | Registry repozytoriów i ryzyko |
| `api/` | OpenAPI / REST (później) |
| `events/` | AsyncAPI / eventy (później) |
| `storage/` | Buckety, ścieżki (później) |
| `models/` | Modele ML / routing (później) |
| `data/` | Schematy danych (później) |
| `approvals/` | Stany taska, bramki, eventy approval-first ([EPIC-010](../specs/epics/EPIC-010-approval-pr-flow.md)) |

## MVP (Faza 1)

Obecnie utrzymujemy tylko:

- [`deploy/`](deploy/)
- [`ansible/`](ansible/)
- [`services/`](services/)
- [`secrets/`](secrets/)
- [`repos/`](repos/)
- [`approvals/`](approvals/) — draft [SPEC-010A](../specs/SPEC-010A-approval-state-contracts.md)

Rozszerzenia (EPIC-005):

- [`storage/runtime-paths.yml`](storage/runtime-paths.yml) — ścieżki runtime na hostach (draft migracji)

## Czego NIE trzymamy w contracts/

- wartości sekretów, tokenów, haseł
- plików `.env`
- pełnych runbooków (→ `docs/runbooks/`)
- luźnych pomysłów (→ `BACKLOG.md`)
- logów
- implementacji (kod → repo domenowe)

## Zmiana kontraktu

Przy edycji YAML sprawdź wpływ na repo wskazane w `repos/repositories.yml` i w samym kontrakcie. Zmiany wymagające deployu pozostają **manual_only**.
