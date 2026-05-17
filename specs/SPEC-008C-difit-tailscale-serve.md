# SPEC-008C: difit — Tailscale Serve (tailnet)

Parent: [EPIC-008](epics/EPIC-008-worktree-difit.md)
Status: done

## Problem

difit nie obsługuje base path — Caddy `/diff/` ładuje SPA z `/assets` z roota i się psuje.

## Rozwiązanie (minimalne)

`difit-preview` włącza **Tailscale Serve TCP** na `127.0.0.1:4966`; `difit-stop` wyłącza (`tailscale serve --tcp=4966 off`). Nie rusza istniejącego HTTPS `/:443` → Caddy.

## URL

`http://t630.colobus-micro.ts.net:4966/` (Tailscale na telefonie/laptopie; **nie** `https://` — port to surowe HTTP do difit, szyfrowanie = WireGuard tailnet).

Działa **tylko** gdy `difit-preview` jest uruchomiony; po `difit-stop` → connection refused.

Wyłączenie Serve: `DIFIT_TAILSCALE_SERVE=0 difit-preview …`

## Smoke

```bash
ssh t630 difit-preview /srv/worktrees/homeserver-services-epic008-smoke
curl -sS -o /dev/null -w "%{http_code}\n" http://t630.colobus-micro.ts.net:4966/
ssh t630 difit-stop
```
