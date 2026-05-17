# SPEC-006B: T630 — Forgejo vhost w Caddy (life-platform)

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: done
Repo: life-platform, homeserver-services, workspace
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-006A](SPEC-006A-forgejo-compose-postgres.md)
Blokuje: [SPEC-006C](SPEC-006C-forgejo-org-import.md) *(planowany)*

## Cel

Reverse proxy **`https://t630.colobus-micro.ts.net/git/`** → **`127.0.0.1:3030`**, dostęp wyłącznie z tailnetu/LAN, **jeden** Caddy Docker (`life-platform`) na `:80` — bez drugiego reverse proxy.

## Decyzje

| Temat | Werdykt |
|-------|---------|
| Właściciel ingress | `life-platform/domains/home/configs/caddy/Caddyfile` |
| Upstream | `127.0.0.1:3030` (Forgejo loopback po 006A) |
| Publiczny URL | `https://t630.colobus-micro.ts.net/git/` |
| `FORGEJO__server__ROOT_URL` | `https://t630.colobus-micro.ts.net/git/` |
| Tailscale Serve | Bez zmian: `https://t630.colobus-micro.ts.net/` → `http://127.0.0.1:80` |
| DNS | MagicDNS nie tworzy `git.t630...`; opcjonalny vhost zostaje tylko pod przyszły alias DNS |

## Zakres

### In scope

1. Route `handle_path /git/*` w bloku `:80` Caddyfile.
2. `forgejo_domain` / `forgejo_root_url` w `homeserver-services` (defaults + `group_vars/t630_servers.yml`).
3. Redeploy Caddy (`--tags caddy`) i Forgejo (`--tags forgejo`).
4. Smoke: `curl https://t630.colobus-micro.ts.net/git/`, kontenery Up.
5. Worklog + aktualizacja BACKLOG.

### Out of scope

- Org KERQ, import repo → **006C**
- Backup Restic → **006E**
- Osobny alias DNS / cert TLS dla `git.t630...` (ograniczenie Tailscale MagicDNS)

## Pliki

| Repo | Plik |
|------|------|
| life-platform | `domains/home/configs/caddy/Caddyfile` |
| homeserver-services | `roles/forgejo/defaults/main.yml`, `inventory/group_vars/t630_servers.yml` |
| workspace | ten SPEC, worklog, runbook |

## Smoke

```bash
# Na T630 — Caddy → Forgejo
curl -sS -o /dev/null -w "%{http_code}\n" -H "Host: t630.colobus-micro.ts.net" http://127.0.0.1/git/

# Forgejo loopback (bez zmian)
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3030/

# Z tailnetu
curl -k -sS -o /dev/null -w "%{http_code}\n" https://t630.colobus-micro.ts.net/git/
```

## Rollback

1. Usuń route `/git` z Caddyfile, `docker compose up -d --force-recreate caddy`.
2. Przywróć stare `forgejo_domain` / `forgejo_root_url`, `docker compose up -d` w katalogu forgejo.

## Następne

- [SPEC-006C](SPEC-006C-forgejo-org-import.md) — org KERQ, import `homeserver-services`, wyłączona rejestracja
