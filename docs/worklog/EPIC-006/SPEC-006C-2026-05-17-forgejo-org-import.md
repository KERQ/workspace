# SPEC-006C — 2026-05-17 — Forgejo org KERQ + import homeserver-services

## Wykonane

- Admin `karol.kurek` był już utworzony.
- Organizacja `KERQ` utworzona jako private.
- Repo `KERQ/homeserver-services` utworzone jako private.
- Dodano klucz SSH `id_ed25519.pub` użytkownika do Forgejo.
- Import wykonany przez SSH push z lokalnego checkoutu, bez zmiany `origin`.
- Tymczasowe tokeny API `spec-006c-*` usunięte.

## Smoke

| Test | Wynik |
|------|--------|
| `KERQ` w DB | OK |
| `KERQ/homeserver-services` | private, `is_empty=false`, default branch `main` |
| `git ls-remote ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git` | OK |
| Branche | `main`, `feat/t630-local-llm-poc-llamacpp`, `backup/rollback-homeserver-20260515-191303` |
| Tag | `backup-homeserver-20260515-191303` |
| Tymczasowe tokeny API | brak |

## Uwagi

- `POST /repos/migrate` z `https://github.com/KERQ/homeserver-services.git` utworzył pusty rekord repo, ale clone po stronie T630 nie miał credentiali GitHuba. Repo zostało usunięte i odtworzone jako puste, po czym zasilone przez SSH push.
- HTTPS git auth w Forgejo 11 zwracał `credentials incorrect/expired`; dla MVP używamy SSH.
- Anonimowy `curl` do prywatnego repo zwraca `404`, co jest oczekiwane.

## Następne

- SPEC-006D: ustawić `origin`/`github`, wykonać branch testowy i PR smoke.
