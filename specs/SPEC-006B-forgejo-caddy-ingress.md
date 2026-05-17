# SPEC-006B: T630 — Forgejo vhost w Caddy (life-platform)

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: draft *(szkic)*
Repo: life-platform (+ workspace)
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-006A](SPEC-006A-forgejo-compose-postgres.md)

## Cel (szkic)

Reverse proxy `git.<tailnet>` → `127.0.0.1:3030`, Tailscale-only, bez drugiego Caddy na `:80`.

Szczegóły po zamknięciu 006A.
