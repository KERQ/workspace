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

## MVP (Faza 1)

Obecnie utrzymujemy tylko:

- [`deploy/`](deploy/)
- [`ansible/`](ansible/)
- [`services/`](services/)
- [`secrets/`](secrets/)
- [`repos/`](repos/)

## Czego NIE trzymamy w contracts/

- wartości sekretów, tokenów, haseł
- plików `.env`
- pełnych runbooków (→ `docs/runbooks/`)
- luźnych pomysłów (→ `BACKLOG.md`)
- logów
- implementacji (kod → repo domenowe)

## Zmiana kontraktu

Przy edycji YAML sprawdź wpływ na repo wskazane w `repos/repositories.yml` i w samym kontrakcie. Zmiany wymagające deployu pozostają **manual_only**.
