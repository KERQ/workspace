# SPEC-006A: T630 — Forgejo + PostgreSQL (Compose + Ansible)

Parent: [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
Status: done
Repo: homeserver-services (+ workspace: runbook, contracts draft)
Owner: karolkurek
Risk: medium
Type: infra
Zablokowany przez: [SPEC-016](../SPEC-016-t630-caddy-unify-docker.md) (Caddy Docker), [EPIC-014](../epics/EPIC-014-restic-minio-offbox-backup.md) (backup off-box)
Blokuje: [SPEC-006B](SPEC-006B-forgejo-caddy-ingress.md) *(planowany)* — vhost Caddy

## Cel

Dostarczyć **Docker Compose + rolę Ansible** dla **Forgejo + PostgreSQL** na T630: dane pod `/srv/ai-stack/forgejo/`, bind **loopback** (bez publicznego UI), gotowe do smoke po **006B** (Caddy) i **006C** (org/import).

## Kontekst

- Audyt T630 (2026-05-17): `127.0.0.1:3000` zajęty przez **OpenClaw Studio** — Forgejo **nie** może używać host `:3000`.
- `2222` wolny; `/srv/ai-stack` nie istnieje — do utworzenia.
- Ingress HTTP: **life-platform** Caddy (SPEC-016) — w 006A tylko backend `127.0.0.1:3030`.
- Szkic compose: [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../docs/ideas/openclaw_architektura_forgejo_github_backup.md) §7.

## Decyzje

| Temat | Wartość | Uwagi |
|-------|---------|-------|
| Właściciel Ansible/compose | **homeserver-services** | Zgodnie z EPIC-006 matrix |
| Obraz Forgejo | `codeberg.org/forgejo/forgejo:11-rootless` | Pin; rootless, UID 1000 (`t630`) |
| PostgreSQL | `postgres:16-alpine` | Osobny kontener `forgejo-db` |
| Dane | `/srv/ai-stack/forgejo/data`, `.../postgres` | Persistent |
| Compose na hoście | `/opt/homeserver-services/t630-config/forgejo/` | Sync z repo (Ansible template) |
| Web bind | `127.0.0.1:3030` → kontener `3000` | Konflikt z OpenClaw Studio uniknięty |
| Git SSH | `0.0.0.0:2222` → kontener `2222` | Tailscale/LAN; `git@t630 -p 2222` |
| Domena (env) | `git.t630.homelab.local` | Placeholder — **006B** dopasuje do realnego tailnet FQDN |
| Rejestracja | `DISABLE_REGISTRATION=true` | Admin w 006C |
| Actions | wyłączone w MVP | `FORGEJO__actions__ENABLED=false` |
| Sekrety | `inventory/host_vars/t630.yml` + `.env` na hoście `0600` | Nie w Git |

## Zakres

### In scope

1. Rola Ansible `homeserver-services/roles/forgejo`:
   - katalogi `/srv/ai-stack/forgejo/{data,postgres}`,
   - `docker-compose.yml` + `.env` z szablonów,
   - `docker compose up -d` (tag `forgejo`).
2. `playbooks/t630.yml` — rola `forgejo`, tag `forgejo`.
3. Zmienne `group_vars/t630_servers.yml` (bez sekretów).
4. `ufw` / dokumentacja: port **2222** (opcjonalnie w tym SPEC jeśli już zarządzane w core).
5. Preflight w SPEC: `docker compose config`, `--syntax-check`.
6. Smoke **po deploy** (bez Caddy): `curl 127.0.0.1:3030`, kontenery healthy.
7. Runbook deploy: `docs/runbooks/t630-forgejo-deploy.md`.
8. Aktualizacja `contracts/services/ports.yml` — `host_port: 3030`, status nadal `planned` do 006E.

### Out of scope

- Caddy vhost, TLS, tailnet FQDN → **006B**.
- Org `KERQ`, import repo, admin user → **006C**.
- `git remote` cutover, PR smoke → **006D**.
- Backup Forgejo w Restic (włączenie `t630-forgejo`) → **006E**.
- Push mirror GitHub.

## Pliki / obszary

### Read

- [EPIC-006](epics/EPIC-006-forgejo-mvp.md)
- `homeserver-services/playbooks/t630.yml`
- [SPEC-015](SPEC-015-t630-g2-service-dashboard.md) — port 3000 conflict
- Forgejo Docker docs: https://forgejo.org/docs/latest/admin/installation/docker/

### Write

| Repo | Pliki |
|------|-------|
| `homeserver-services` | `roles/forgejo/{defaults,tasks,templates,handlers}/` |
| `homeserver-services` | `inventory/group_vars/t630_servers.yml` |
| `homeserver-services` | `playbooks/t630.yml` |
| `workspace` | ten SPEC, runbook, worklog placeholder |
| `workspace` | `contracts/services/ports.yml` — `host_port`, komentarz |

### Forbidden

- Bind `127.0.0.1:3000` na hoście.
- Sekrety w commitach (`FORGEJO_DB_PASSWORD`, admin hasło).
- `docker compose up` bez `APPROVE_DEPLOY=yes` w procedurze deploy.
- Publiczny `0.0.0.0:3030`.

## Zmienne Ansible (propozycja)

```yaml
# group_vars/t630_servers.yml
forgejo_enabled: true
forgejo_compose_dir: "{{ homeserver_runtime_root | default('/opt/homeserver-services') }}/t630-config/forgejo"
forgejo_data_root: /srv/ai-stack/forgejo
forgejo_image: codeberg.org/forgejo/forgejo:11-rootless
forgejo_db_image: postgres:16-alpine
forgejo_http_bind: "127.0.0.1"
forgejo_http_port: 3030
forgejo_ssh_port: 2222
forgejo_domain: git.t630.homelab.local  # 006B: tailnet FQDN
```

Sekrety w `inventory/host_vars/t630.yml` (gitignored):

```yaml
forgejo_db_password: "<generated>"
# forgejo_admin_* — opcjonalnie 006C
```

## Do zrobienia

- [x] Rola `forgejo` + szablony compose/env (`homeserver-services` `6a5d9e6`)
- [x] syntax-check OK
- [x] `docker compose config` OK (w roli Ansible)
- [x] Deploy T630 `--tags forgejo`
- [x] Smoke: kontenery Up, HTTP 127.0.0.1:3030
- [x] Worklog
- [x] EPIC-006 child → done

## Definition of Ready

- [x] EPIC-014 done, SPEC-016 done
- [ ] `forgejo_db_password` przygotowane (host_vars / generator przy pierwszym deploy)
- [ ] Potwierdzenie domeny tailnet dla `FORGEJO__server__*` (może być placeholder do 006B)
- [ ] Approval na deploy T630

## Definition of Done

- [x] Katalogi `/srv/ai-stack/forgejo/data` — UID 1000; `/srv/ai-stack/forgejo/postgres` — UID/GID 70 (`postgres:16-alpine`)
- [x] `forgejo`, `forgejo-db` Up (healthy)
- [x] HTTP loopback 3030 OK
- [x] `:3030` loopback, `:2222` nasłuch
- [x] compose config OK
- [x] Sekrety poza Git
- [x] Runbook opublikowany

## Test plan

### Faza A — przed deploy

```bash
cd ~/repos/homeserver-services
ansible-playbook playbooks/t630.yml -l t630 --tags forgejo --syntax-check

# Po sync szablonów na T630 (lub lokalnie z wygenerowanym .env.test):
docker compose -f roles/forgejo/files/... config  # lub na hoście:
ssh t630@192.168.1.20 'cd /opt/homeserver-services/t630-config/forgejo && docker compose config'

ssh t630@192.168.1.20 'ss -lntp | grep -E ":3000|:3030|:2222"'
```

### Faza B — po deploy

```bash
ssh t630@192.168.1.20 '
  docker ps --filter name=forgejo --format "{{.Names}} {{.Status}}"
  curl -sS -o /dev/null -w "http:%{http_code}\n" http://127.0.0.1:3030/
  ss -lntp | grep -E ":3030|:2222"
'
```

### Faza C — nie w tym SPEC

- HTTPS przez Caddy (`006B`)
- `git push` / PR (`006C`/`006D`)

## Rollback

```bash
ssh t630@192.168.1.20 'cd /opt/homeserver-services/t630-config/forgejo && docker compose down'
# Dane zostają w /srv/ai-stack/forgejo — usunąć tylko przy świadomym rollback:
# sudo rm -rf /srv/ai-stack/forgejo
```

## Approval gates

| Gate | Wymagane |
|------|----------|
| Merge roli do main | review |
| Pierwszy `docker compose up` na T630 | `APPROVE_DEPLOY=yes` |

## Wpływ na kolejne SPECs

```text
006A (ten SPEC) → 006B Caddy git.*
               → 006C org/import
               → 006D remotes/PR
               → 006E backup + contracts active
```

## Work log

- [2026-05-17 — deploy T630](../docs/worklog/EPIC-006/SPEC-006A-2026-05-17-forgejo-compose-deploy.md)

## Prompt plan

1. Zaimplementuj rolę `forgejo` w homeserver-services.
2. Syntax-check; `docker compose config`.
3. Deploy po approval; smoke 127.0.0.1:3030.
4. Nie konfiguruj Caddy ani importu repo.

## Na później

- Podnieść wersję Forgejo po stabilnym MVP.
- Włączyć `t630-forgejo` w Restic po utworzeniu `/srv/ai-stack/forgejo` (006E).
