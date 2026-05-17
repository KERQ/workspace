# SPEC-014B — 2026-05-17 — Restic MinIO bucket + T630 access

## Cel

Bucket `restic-backups`, user `restic-t630`, LAN API MinIO, credentials na T630.

## Wykonane

### Kod

- `homeserver-services`: `roles/trading/tasks/restic-minio.yml`, policy template, LAN bind `192.168.1.19:19000`, mc alias na bind IP.
- `homeserver-core`: rola `roles/restic`, `/etc/restic/credentials.env` (mode 600).
- Sekret kontrolera: `homeserver-services/inventory/.secrets/restic_minio_secret_key` (gitignored).

### Deploy

- G2: `ansible-playbook playbooks/g2.yml -l g2 --tags trading-minio,restic-minio` — bucket/user OK (playbook kontynuował też taski Airflow przez tagi roli `trading`).
- T630: `ansible-playbook playbooks/t630.yml -l t630 --tags restic-minio` — OK.

## Testy

| Test | Wynik |
|------|--------|
| T630 → `curl http://192.168.1.19:19000/minio/health/live` | OK |
| G2 `mc admin user list` | `restic-t630` enabled, policy `restic-t630-rw` |
| T630 `sudo` + creds → `mc ls g2restic/restic-backups` | OK |
| T630 `mc ls g2restic/raw-gdelt` | Access Denied (oczekiwane) |

## Uwagi

- `/etc/restic/credentials.env` — root `600`; operacje `mc`/`restic` przez `sudo` (SPEC-014C).
- `RESTIC_PASSWORD` — jeszcze nie ustawione (014C).
- Healthcheck MinIO w roli używa `trading_minio_api_bind` zamiast stałego `127.0.0.1`.

## Następne

- SPEC-014C: `restic init` + pierwszy backup `/opt/backups`.
