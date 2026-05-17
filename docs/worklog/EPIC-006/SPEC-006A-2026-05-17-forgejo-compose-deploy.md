# SPEC-006A — 2026-05-17 — Forgejo compose deploy T630

## Wykonane

- `forgejo_db_password` w `homeserver-services/inventory/host_vars/t630.yml` (lokalnie, gitignored)
- Deploy: `ansible-playbook playbooks/t630.yml -l t630 --tags forgejo`
- Obrazy: `forgejo:11-rootless`, `postgres:16-alpine`

## Smoke

| Test | Wynik |
|------|--------|
| `docker ps` forgejo, forgejo-db | Up / healthy |
| `curl http://127.0.0.1:3030/` | OK (200/302) |
| `:3030` bind | 127.0.0.1 |
| `:2222` bind | *:2222 |
| Dane | `/srv/ai-stack/forgejo/data`, `.../postgres` |

## Uwagi

- Domena env placeholder: `git.t630.homelab.local` — **006B** powinien ustawić tailnet FQDN (np. `git.t630.colobus-micro.ts.net`).
- `forgejo_db_password` tylko w lokalnym host_vars — nie commitować.

## Następne

- SPEC-006B: Caddy vhost w life-platform
- SPEC-006C: org KERQ + import homeserver-services
