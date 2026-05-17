# T630/G2 Service Dashboard

Stan z audytu: **2026-05-17** (Caddy zaktualizowany po SPEC-016). One-pager operacyjny — **dashboard web** to osobny backlog (aplikacja WWW).

## Skrót

| Host | Ogólny stan | Najważniejszy problem | Dysk |
|------|-------------|-----------------------|------|
| T630 | Usługi główne działają; Caddy Docker **Up** | `caddy.service` wyłączony (SPEC-016, 2026-05-17) | `/`: 55G wolne, 49% użycia |
| G2 | Usługi główne działają | Brak failed systemd units; Caddy działa | `/mnt/seagate`: ~21T wolne |

## T630

Host: `t630@192.168.1.20`

### Web / UI

| Usługa | Link / dostęp | Status | Port / bind | Uwagi |
|--------|---------------|--------|-------------|-------|
| Home Assistant | `http://192.168.1.20:8123/` | OK (`200`) | `0.0.0.0:8123` | Kontener `homeassistant` up |
| Zigbee2MQTT | `http://192.168.1.20:8099/` | OK (`200`) | `0.0.0.0:8099` | Kontener `zigbee2mqtt` up |
| ESPHome | `http://192.168.1.20:6052/` | OK (`200`) | `0.0.0.0:6052` | Kontener `esphome` up |
| OpenClaw Studio | SSH tunnel: `http://127.0.0.1:3000/` | OK (`200`) | `127.0.0.1:3000` | `openclaw-studio.service` user service |
| ClawSuite | `http://192.168.1.20:3001/` | OK (`200`) | `0.0.0.0:3001` | User service `clawsuite` |
| Paperclip | `http://192.168.1.20:3002/` | Redirect (`302`) | `0.0.0.0:3002` | User service `paperclip` |
| OpenClaw Gateway | local: `http://127.0.0.1:18789/` | OK (`200`) | `127.0.0.1:18789`, `[::1]:18789` | Internal/API |
| cAdvisor | `http://192.168.1.20:9080/` | Redirect (`307`) | `0.0.0.0:9080` | Healthy |
| Caddy (Docker) | `http://192.168.1.20/` | OK (`200` root) | `*:80` | Kontener `caddy`, `network_mode: host` |

### Containers

| Kontener | Status | Porty | Uwagi |
|----------|--------|-------|-------|
| `homeassistant` | Up 3 days | host network / `8123` | OK |
| `zigbee2mqtt` | Up 3 days | `8099->8080` | OK |
| `mosquitto` | Up 3 days healthy | `1883` | OK |
| `esphome` | Up 3 days healthy | host network / `6052` | OK |
| `samba` | Up 3 days healthy | `139`, `445` | OK |
| `cadvisor` | Up 3 days healthy | `9080->8080` | OK |
| `openclaw-control-plane-redis` | Up 3 days | `127.0.0.1:56379` | OK |
| `openclaw-control-plane-postgres` | Up 3 days | `127.0.0.1:55432` | OK |
| `plane-plane-minio-1` | Up 3 days | `9001`, `9002` | OK |
| `plane-datalake-minio-1` | Up 3 days | `9011`, `9012` | OK |
| `timescaledb` | Restarting | none | Follow-up: sprawdzić osobno |
| `caddy` | Up | `*:80` | Docker, `network_mode: host` (SPEC-016) |

### Systemd / User Services

| Service | Status | Uwagi |
|---------|--------|-------|
| `caddy.service` | **disabled** | Wyłączony SPEC-016; ingress = kontener Docker |
| `openclaw-studio.service` | active | User service |
| `clawsuite.service` | active | User service |
| `paperclip.service` | active | User service |
| Failed units | 0 | OK |

### Caddy (SPEC-016 done)

- Właściciel `:80`: kontener Docker `caddy` (`life-platform`).
- `caddy.service`: disabled.
- Runbook operacyjny: [t630-caddy-unify.md](t630-caddy-unify.md).
- Vhost Forgejo (EPIC-006): ten sam `Caddyfile` w `life-platform`.

## G2

Host: `g2@192.168.1.19`

### Web / UI

| Usługa | Link / dostęp | Status | Port / bind | Uwagi |
|--------|---------------|--------|-------------|-------|
| G2 Caddy | `http://192.168.1.19/` | OK (`200`) | `*:80`, `*:443` | Kontener `caddy` up |
| Airflow | local: `http://127.0.0.1:18080/` | Responds (`404`) | `127.0.0.1:18080` | Webserver up; właściwa ścieżka może być przez Caddy/subpath |
| Grafana | `http://192.168.1.19:3001/` | Redirect (`301`) | `0.0.0.0:3001` | OK |
| Uptime Kuma | `http://192.168.1.19:3002/` | Redirect (`302`) | `0.0.0.0:3002` | OK |
| LiteLLM | local: `http://127.0.0.1:4001/` | OK (`200`) | `127.0.0.1:4001` | Internal/tunnel |
| Security Node | `http://192.168.1.19:4000/` | Responds (`404`) | `0.0.0.0:4000` | Service up |
| Infisical | `http://192.168.1.19:8081/` | OK (`200`) | `0.0.0.0:8081` | Direct port |
| Plane | local: `http://127.0.0.1:8085/` | OK (`200`) | `127.0.0.1:8085` | Proxy container |
| MinIO (Restic candidate) | local console: `http://127.0.0.1:19001/` | OK (`200`) | `127.0.0.1:19000/19001` | Candidate for EPIC-014 |
| Jupyter | local: `http://127.0.0.1:18888/` | Responds (`404`) | `127.0.0.1:18888` | Web service up; token/path likely needed |
| Ollama | `http://192.168.1.19:11434/` | OK (`200`) | `0.0.0.0:11434` | API |

### Containers

| Grupa | Kontenery | Status |
|-------|-----------|--------|
| Airflow | scheduler, worker, webserver | Up / healthy |
| Monitoring | `grafana`, `prometheus`, `blackbox-exporter`, `cadvisor`, `node-exporter` | Up |
| Memory/OpenClaw | `mcp-memory`, `mem0-api`, `qdrant` | Up |
| LLM/API | `litellm`, `security-node`, `ollama` | Up |
| Plane | proxy, live, space, admin, web, backend, db, mq, minio, redis | Up / healthy where applicable |
| Storage | `minio-minio-1`, `timescaledb`, `redis`, `samba` | Up / healthy where applicable |
| Privacy | `presidio-analyzer`, `presidio-anonymizer` | Up |
| Infisical | backend, db, redis | Up / db healthy |
| Caddy | `caddy` | Up |

### Systemd

| Check | Status |
|-------|--------|
| Failed units | 0 |

## Port Notes

| Port | T630 | G2 | Uwagi |
|------|------|----|-------|
| `80` | Docker `caddy` OK | Docker `caddy` OK | Gotowe pod Forgejo vhost |
| `443` | Tailscale/listener active | Docker `caddy` OK | |
| `3000` | `openclaw-studio` on `127.0.0.1` | internal Plane/Presidio containers | Forgejo web nie powinien bindwać host `3000` |
| `3001` | ClawSuite | Grafana | |
| `3002` | Paperclip | Uptime Kuma | |
| `2222` | wolny w poprzednim checku | nieużywany | Candidate for Forgejo SSH |
| `19000/19001` | n/a | MinIO local only | Candidate Restic backend |

## Next

- Dashboard **web** (aplikacja) — backlog Next, osobny SPEC.
- Kontynuować EPIC-014B: MinIO bucket + dostęp T630 -> G2.
- Przed EPIC-006: zarezerwować docelowe porty Forgejo (`2222` SSH, web przez Caddy bez host bind `3000`).
