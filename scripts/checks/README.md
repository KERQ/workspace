# Checks — trwała diagnostyka

## Zasada

Checki mają być **trwałymi artefaktami**, nie jednorazowymi komendami z czatu.

Jeśli diagnostyka wymaga poleceń shell lub SQL, zapisz je jako skrypt lub plik SQL w tym drzewie.

## Preferowany wzór

```text
scripts/checks/<obszar>/<nazwa_checka>/check_*.sh
scripts/checks/<obszar>/<nazwa_checka>/sql/*.sql
```

Przykład obszarów: `openclaw`, `litellm`, `deploy`, `timescale`, `home-assistant`.

## Zasady

- **Bez sekretów** w plikach — używaj zmiennych środowiskowych lub dokumentuj wymagane nazwy scope z [`../../contracts/secrets/scopes.yml`](../../contracts/secrets/scopes.yml), nie wartości.
- Check **read-only** domyślnie; mutacje wymagają runbooka i approval.
- Każdy check powinien mieć krótki README w swoim katalogu (opcjonalnie) z: cel, jak uruchomić, oczekiwany wynik.

## Powiązanie ze SPEC

Test plan w SPEC może wskazywać na konkretny check w `scripts/checks/` zamiast powtarzać komendy.
