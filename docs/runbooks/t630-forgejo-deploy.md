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

## Caddy / tailnet (SPEC-006B)

- URL: `https://t630.colobus-micro.ts.net/git/` → `127.0.0.1:3030` w `life-platform/.../caddy/Caddyfile`
- Redeploy Caddy: `ansible-playbook playbooks/t630.yml -l t630 --tags caddy` (z `life-platform/domains/home/ansible`)
- Redeploy Forgejo (ROOT_URL): `APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags forgejo`
- Smoke: `curl -k https://t630.colobus-micro.ts.net/git/` → 200/302
- Tailscale Serve: `https://t630.colobus-micro.ts.net/` → Caddy `:80`; MagicDNS nie rozwiązuje automatycznie `git.t630.*`

[Szczegóły](../../specs/SPEC-006B-forgejo-caddy-ingress.md)

## Org / repo (SPEC-006C)

- Org: `KERQ`
- Repo: `KERQ/homeserver-services` (private)
- SSH URL: `ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git`
- UI URL: `https://t630.colobus-micro.ts.net/git/KERQ/homeserver-services`
- Smoke:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git ls-remote ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git
```

Po SPEC-006D lokalny `origin` wskazuje Forgejo, a GitHub jest dostępny jako `github`.

## Remotes / PR smoke (SPEC-006D)

`homeserver-services` po cutover:

```bash
origin  ssh://git@t630.colobus-micro.ts.net:2222/KERQ/homeserver-services.git
github  https://github.com/KERQ/homeserver-services.git
```

Smoke:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git ls-remote origin refs/heads/test/forgejo-smoke-20260517
```

PR smoke: `https://t630.colobus-micro.ts.net/git/KERQ/homeserver-services/pulls/1`

Merge PR pozostaje ręczny.

## Backup (SPEC-006E)

Lokalny dump DB:

```bash
ssh t630@192.168.1.20 'sudo -u t630 /usr/local/bin/backup-forgejo.sh'
```

Output: `/opt/backups/forgejo/forgejo-*.sql.gz` (retencja lokalna 7 dni).

Restic off-box:

- tag: `t630-forgejo`
- ścieżki: `/opt/backups/forgejo`, `/srv/ai-stack/forgejo`
- cron: `30 4 * * * /usr/local/bin/restic-backup-all.sh`

Restore drill dumpu:

```bash
ssh t630@192.168.1.20 'sudo bash -c "
  set -a; . /etc/restic/credentials.env; set +a
  export AWS_S3_FORCE_PATH_STYLE=true
  rm -rf /tmp/restic-forgejo-restore-test
  mkdir -p /tmp/restic-forgejo-restore-test
  restic restore latest --tag t630-forgejo \
    --target /tmp/restic-forgejo-restore-test \
    --include /opt/backups/forgejo/*.sql.gz
  find /tmp/restic-forgejo-restore-test/opt/backups/forgejo \
    -type f -name \"*.sql.gz\" -exec gzip -t {} \\;
"'
```
