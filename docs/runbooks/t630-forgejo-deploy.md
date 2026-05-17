# Runbook: T630 — deploy Forgejo (SPEC-006A)

Wymaga: [SPEC-016](../../specs/SPEC-016-t630-caddy-unify-docker.md) (Caddy), [EPIC-014](../../specs/epics/EPIC-014-restic-minio-offbox-backup.md) (backup).

## Preflight

```bash
ssh t630@192.168.1.20 'ss -lntp | grep -E ":3000|:3030|:2222"'
# :3000 = OpenClaw Studio — Forgejo używa :3030
```

## Sekrety

W `homeserver-services/inventory/host_vars/t630.yml` (gitignored):

```yaml
forgejo_db_password: "<strong-password>"
```

## Deploy

```bash
cd ~/repos/homeserver-services
ansible-playbook playbooks/t630.yml -l t630 --tags forgejo --syntax-check
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags forgejo
```

## Smoke

```bash
ssh t630@192.168.1.20 '
  docker ps --filter name=forgejo
  curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3030/
'
```

## Rollback

```bash
ssh t630@192.168.1.20 'cd /opt/homeserver-services/t630-config/forgejo && docker compose down'
```

## Następny krok

[SPEC-006B](../../specs/SPEC-006B-forgejo-caddy-ingress.md) — vhost w `life-platform` Caddyfile.
