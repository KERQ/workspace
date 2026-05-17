# SPEC-016 — 2026-05-17 — T630 Caddy unify (Docker)

## Cel

Jeden reverse proxy na `:80`: Docker Caddy z `life-platform`; wyłączenie `caddy.service`.

## Wykonane

1. Backup: `/tmp/Caddyfile.systemd.bak.20260517`, `/tmp/Caddyfile.compose.bak.20260517`
2. `diff` host vs deploy — pliki zgodne (5214 B)
3. `sudo systemctl disable --now caddy.service` → disabled, inactive
4. `docker compose stop caddy` + `docker rm -f caddy` + `docker compose up -d caddy` (wymagane po wcześniejszym restart loop)
5. Stan końcowy: kontener `caddy` **Up**, `*:80` → proces caddy w kontenerze (host network)

## Smoke (127.0.0.1)

| Trasa | Kod |
|-------|-----|
| `/` | 200 |
| `/HA` | 302 |
| `/zigbee2mqtt` | 302 |
| `/clawsuite/` | 307 |
| `/openclaw/` | 200 |
| `:8123` HA | 200 |
| `:8099` Zigbee | 200 |

## Uwagi

- Po samym `disable systemd` kontener nadal restartował się z `address already in use` — pomogło pełne zatrzymanie i recreate kontenera przy wolnym `:80`.
- `systemctl mask` nie stosowano.

## Następne

- EPIC-006 SPEC-006B: vhost Forgejo w `life-platform/.../caddy/Caddyfile`
- Dashboard **web** — osobny item w BACKLOG (nie ten one-pager)
