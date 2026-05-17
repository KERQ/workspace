# EPIC-008 — worktree + difit (2026-05-17)

## Wdrożone

- Role Ansible: `homeserver-services/roles/worktree`, `roles/difit`
- Ścieżki T630: `/srv/repos/homeserver-services` (bare mirror), `/srv/worktrees/`
- Skrypty: `/opt/homeserver-services/bin/{worktree-create,worktree-remove,difit-preview,difit-stop}`
- Obraz: `homeserver-difit:5.0.1` (difit + git + `safe.directory *`)

## Smoke

```text
worktree-create homeserver-services epic008-smoke main → OK
difit-preview → container Up, curl http://127.0.0.1:4966/ → 200
```

## Uwagi operacyjne

- Klon Forgejo z T630 wymaga klucza SSH `t630` — na razie mirror z `/opt/paperclip-workspaces/homeserver-services` (bare).
- `worktree-create` domyślnie `main` (nie `origin/main`) — fetch Forgejo best-effort.
- difit: dostęp z laptopa przez `ssh -L 4966:127.0.0.1:4966 t630@192.168.1.20`.

## 008C (Tailscale Serve)

- `difit-preview` / `difit-stop` — Serve TCP `:4966` → `http://t630.colobus-micro.ts.net:4966/` (on-demand)
- Bez Caddy `/diff/` (brak base path w difit).
