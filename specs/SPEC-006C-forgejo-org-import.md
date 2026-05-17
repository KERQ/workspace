# SPEC-006C: T630 — Forgejo org KERQ + import homeserver-services

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: done
Repo: workspace (+ manual ops)
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-006B](SPEC-006B-forgejo-caddy-ingress.md)
Blokuje: [SPEC-006D](SPEC-006D-forgejo-remotes-pr-smoke.md) *(planowany)*

## Cel

Zainicjalizować Forgejo po stronie aplikacji: admin istnieje, rejestracja publiczna wyłączona, organizacja **`KERQ`** utworzona, repo pilotażowe **`KERQ/homeserver-services`** zaimportowane bez zmiany lokalnego `origin`.

## Wykonane

1. Potwierdzono admina `karol.kurek`.
2. Utworzono organizację `KERQ` (private).
3. Utworzono prywatne repo `KERQ/homeserver-services`.
4. Dodano publiczny klucz SSH użytkownika do Forgejo.
5. Wypchnięto lokalne branche i tagi przez SSH:
   - `main`
   - `feat/t630-local-llm-poc-llamacpp`
   - `backup/rollback-homeserver-20260515-191303`
   - `backup-homeserver-20260515-191303`
6. Usunięto tymczasowe tokeny API `spec-006c-*`.

## Decyzje / uwagi

| Temat | Werdykt |
|-------|---------|
| URL UI | `https://t630.colobus-micro.ts.net/git/KERQ/homeserver-services` |
| Git SSH | `ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git` |
| Git HTTPS | Nie używać w 006C; token HTTPS w Forgejo 11 zwracał `credentials incorrect/expired` |
| GitHub import API | Nieudany bez credentiali GitHuba po stronie T630; repo odtworzone jako puste i zasilone przez SSH push |
| Lokalny `origin` | Bez zmian, nadal GitHub; cutover dopiero w 006D |

## Smoke

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git ls-remote ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git
```

Wynik: `HEAD`, 3 branche i 1 tag widoczne w Forgejo.

## Następne

- [SPEC-006D](SPEC-006D-forgejo-remotes-pr-smoke.md) — `origin`/`github` remotes, SSH smoke, branch testowy + PR.
