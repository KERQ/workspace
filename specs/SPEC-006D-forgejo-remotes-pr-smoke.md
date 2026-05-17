# SPEC-006D: T630 — Forgejo remotes + PR smoke

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: done
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-006C](SPEC-006C-forgejo-org-import.md)
Blokuje: [SPEC-006E](SPEC-006E-forgejo-backup-contracts.md) *(planowany)*

## Cel

Przestawić lokalny checkout `homeserver-services` na Forgejo jako `origin`, zachować GitHub jako ręczny remote `github`, wykonać SSH push smoke i utworzyć testowy PR w Forgejo.

## Wykonane

1. `origin` ustawiony na Forgejo:
   `ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git`
2. `github` ustawiony na dotychczasowy GitHub:
   `https://github.com/KERQ/homeserver-services.git`
3. Smoke branch utworzony bez checkoutu roboczego (przez `git commit-tree`, aby ominąć `git-crypt` smudge na sekretach):
   `test/forgejo-smoke-20260517`
4. Branch wypchnięty do Forgejo przez SSH.
5. PR smoke utworzony:
   `https://t630.colobus-micro.ts.net/git/KERQ/homeserver-services/pulls/1`
6. Tymczasowy token API `spec-006d-pr` usunięty.
7. Po akceptacji użytkownika PR `#1` zmerge'owany; testowy branch `test/forgejo-smoke-20260517` usunięty z remote.

## Smoke

```bash
git -C ~/repos/homeserver-services remote -v

GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git ls-remote origin refs/heads/test/forgejo-smoke-20260517
```

Wynik:

- `origin` → Forgejo SSH
- `github` → GitHub HTTPS
- PR `#1` zmerge'owany, `has_merged=true`
- `origin/main` wskazuje merge commit `18ff162`

## Uwagi

- Merge PR wykonany po explicite approval użytkownika (`tak`).
- Lokalny checkout `homeserver-services` nadal ma niezatwierdzone zmiany robocze z 006B/006C/naprawy Postgres; smoke commit nie dotykał tych plików.
- GitHub mirror nie został skonfigurowany.

## Następne

- [SPEC-006E](SPEC-006E-forgejo-backup-contracts.md) — backup Forgejo + contracts/runbook.
