# Runbook: T630 — ujednolicenie Caddy (Docker, life-platform)

Operacje dla [SPEC-016](../../specs/SPEC-016-t630-caddy-unify-docker.md). **Wymaga approval** przed wyłączeniem `caddy.service`.

## Cel

Jeden reverse proxy na `:80`: kontener Docker Caddy z `life-platform`, bez konfliktu z `systemd caddy.service`.

## Preflight

```bash
ssh t630@192.168.1.20 '
  systemctl status caddy --no-pager
  docker ps -a --filter name=caddy
  sudo ss -lntp "sport = :80"
  diff -u /etc/caddy/Caddyfile /opt/life-platform-t630/t630-config/caddy/Caddyfile || true
'
```

Zapisz wynik diff. Jeśli host ma unikalne bloki — najpierw merge do repo `life-platform`, potem deploy.

## Backup (opcjonalnie)

```bash
ssh t630@192.168.1.20 '
  sudo cp -a /etc/caddy/Caddyfile /tmp/Caddyfile.systemd.bak.$(date +%Y%m%d)
  cp -a /opt/life-platform-t630/t630-config/caddy/Caddyfile /tmp/Caddyfile.compose.bak.$(date +%Y%m%d)
'
```

## Krok 1 — wyłączenie hostowego Caddy

**Tylko po explicit approval.**

```bash
ssh t630@192.168.1.20 '
  sudo systemctl disable --now caddy.service
  # opcjonalnie: sudo systemctl mask caddy.service
  systemctl is-enabled caddy || true
  sudo ss -lntp "sport = :80" || true
'
```

## Krok 2 — uruchomienie Docker Caddy

Z hosta (katalog stacku life-platform na T630):

```bash
ssh t630@192.168.1.20 '
  cd /opt/life-platform-t630/t630-config
  docker compose up -d caddy
  docker ps --filter name=caddy
  docker logs caddy --tail 30
'
```

Alternatywnie z Maca (Ansible):

```bash
cd ~/repos/life-platform/domains/home/ansible
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags caddy
```

## Krok 3 — smoke test

```bash
ssh t630@192.168.1.20 '
  for u in / /HA /zigbee2mqtt /clawsuite/ /openclaw/; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "http://127.0.0.1${u}" || echo ERR)
    echo "$u -> $code"
  done
  curl -sS -o /dev/null -w "HA:%{http_code}\n" http://127.0.0.1:8123/
  curl -sS -o /dev/null -w "Z2M:%{http_code}\n" http://127.0.0.1:8099/
'
```

Oczekiwane: brak `address already in use` w logach; `caddy` Up; trasy zwracają sensowne kody (nie connection refused na `:80`).

## Rollback

```bash
ssh t630@192.168.1.20 '
  cd /opt/life-platform-t630/t630-config
  docker compose stop caddy
  sudo systemctl unmask caddy 2>/dev/null || true
  sudo systemctl enable --now caddy.service
'
```

## Po sukcesie

- Zaktualizuj [t630-g2-service-dashboard.md](t630-g2-service-dashboard.md) (status Caddy).
- Odblokuj EPIC-006 SPEC-006B (vhost Forgejo w `life-platform` Caddyfile).
