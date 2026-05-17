# SPEC-006D — 2026-05-17 — Forgejo remotes + PR smoke

## Wykonane

- `homeserver-services`:
  - `origin` → `ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git`
  - `github` → `https://github.com/KERQ/homeserver-services.git`
- Utworzono smoke branch `test/forgejo-smoke-20260517`.
- Wypchnięto smoke branch do Forgejo przez SSH.
- Utworzono PR smoke: `https://t630.colobus-micro.ts.net/git/KERQ/homeserver-services/pulls/1`
- Po akceptacji użytkownika PR `#1` zmerge'owany; remote branch `test/forgejo-smoke-20260517` usunięty.
- Usunięto tymczasowy token API `spec-006d-pr`.

## Smoke

| Test | Wynik |
|------|--------|
| `git remote -v` | `origin` Forgejo, `github` GitHub |
| SSH push branch | OK |
| `git ls-remote origin refs/heads/test/forgejo-smoke-20260517` | OK przed merge |
| PR `#1` | merged, `has_merged=true` |
| `origin/main` | merge commit `18ff162` |
| Tymczasowe tokeny API | brak |

## Uwagi

- Pierwsza próba worktree przerwała się na `git-crypt` smudge dla `inventory/host_vars/t630.yml`; smoke commit wykonano przez `git commit-tree`, bez checkoutu i bez dotykania zmian roboczych.
- Merge PR wykonany dopiero po potwierdzeniu użytkownika.

## Następne

- SPEC-006E: backup Forgejo + `contracts/services/ports.yml`.
