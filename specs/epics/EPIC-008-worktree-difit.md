# EPIC-008: Worktree + difit preview przed commitem

Status: done
Owner: karolkurek
Risk: medium
Repos: homeserver-services, life-platform (opcjonalnie ingress), workspace
Blokuje: [EPIC-010](EPIC-010-approval-pr-flow.md) *(planowany)*
Zablokowany przez: [EPIC-006](EPIC-006-forgejo-mvp.md) **done** (Forgejo `origin`), [EPIC-007](EPIC-007-openclaw-gateway-librechat.md) **done**

## Cel

Agent (lub człowiek) pracuje w **git worktree** per zadanie; przed commitem/PR uruchamia **`difit`** — lokalny podgląd diffu w stylu GitHub.

Po epiku:

- Katalogi `/srv/repos` (klony SoR) i `/srv/worktrees` (izolowane worktree) na T630.
- Skrypty `worktree-create` / `worktree-remove` / `difit-preview`.
- Przypięty obraz Docker `difit:5.0.1` na T630.
- Smoke: worktree testowy + `difit` na `127.0.0.1:4966`.
- Runbook operacyjny.

## Decyzje MVP

| Temat | Wartość |
|-------|---------|
| Host | T630 |
| Repo pilotażowe | `homeserver-services` (Forgejo `origin`) |
| Layout | `/srv/repos/<repo>`, `/srv/worktrees/<repo>-<task-id>` |
| Branch worktree | `task/<task-id>` |
| difit | npm `difit@5.0.1` w obrazie Docker |
| Dostęp UI difit | `127.0.0.1:4966` + **Tailscale Serve TCP** `http://t630…:4966/` ([008C](SPEC-008C-difit-tailscale-serve.md)); fallback SSH tunnel |
| Ingress Caddy `/diff/` | **nie** — difit bez base path; zamiast tego Serve na `:4966` |

## Child SPECs

| SPEC | Status | Opis |
|------|--------|------|
| [SPEC-008A](../SPEC-008A-worktree-layout-scripts.md) | done | `/srv/repos`, `/srv/worktrees`, skrypty worktree |
| [SPEC-008B](../SPEC-008B-difit-docker-image.md) | done | Obraz `homeserver-difit:5.0.1` + `difit-preview` |
| [SPEC-008C](../SPEC-008C-difit-tailscale-serve.md) | done | Tailscale Serve TCP `:4966` (telefon/laptop w tailnecie) |
| [SPEC-008D](../SPEC-008D-smoke-runbook-contracts.md) | done | Smoke HTTP 200, runbook, `ports.yml` |

## Guardrails

```text
- no commit/push bez approval użytkownika
- worktree tylko w /srv/worktrees
- no secrets w worktree (git-crypt / host_vars poza scope)
- difit tylko tailnet (loopback + Tailscale Serve TCP; opcjonalnie SSH tunnel)
- investment-research poza pilotem
```
