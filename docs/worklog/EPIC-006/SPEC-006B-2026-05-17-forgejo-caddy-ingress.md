# SPEC-006B — 2026-05-17 — Forgejo Caddy ingress T630

## Wykonane

- Caddy route `https://t630.colobus-micro.ts.net/git/` → `127.0.0.1:3030` (`life-platform/.../caddy/Caddyfile`)
- `forgejo_domain` / `forgejo_root_url` → `https://t630.colobus-micro.ts.net/git/`
- Deploy: `ansible-playbook ... --tags caddy` + `--tags forgejo`
- Tailscale Serve: przywrócony tylko `/` → `:80` (usunięto eksperymentalny `/git` → `:3030`)

## Smoke

| Test | Wynik |
|------|--------|
| `docker ps` caddy | Up |
| `curl -H Host: t630... http://127.0.0.1/git/` | 200 |
| `curl http://127.0.0.1:3030/` | 200 |
| `curl http://127.0.0.1/` (root) | 200 |
| `curl https://t630.colobus-micro.ts.net/git/` | 200 |
| `FORGEJO__server__ROOT_URL` | `https://t630.colobus-micro.ts.net/git/` |

## Uwagi

- Blok bez `http://` powodował auto-HTTPS Caddy na `:443` → konflikt z Tailscale Serve (`address already in use`). Naprawa: jawny `http://` w site block.
- MagicDNS rozwiązuje `t630.colobus-micro.ts.net`, ale nie `git.t630.colobus-micro.ts.net`. Dlatego działający URL to `/git/` na istniejącym hoście Tailscale.

## Następne

- SPEC-006C: org KERQ + import `homeserver-services`
