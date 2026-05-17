# Runbook: G2 MinIO — backend Restic (SPEC-014B)

Operacje dla [SPEC-014B](../../specs/SPEC-014B-restic-minio-bucket-access.md). **Nie** obejmuje `restic init` (SPEC-014C).

## Architektura

```text
T630 (restic, przyszłość)
  │  HTTP S3 API
  ▼
G2 MinIO 192.168.1.19:19000  (LAN bind po 014B)
  └── bucket: restic-backups
  └── user: restic-t630 (tylko ten bucket)
  └── data: /mnt/seagate/data/minio
```

## Preflight

```bash
ssh g2@192.168.1.19 'curl -fsS http://127.0.0.1:19000/minio/health/live; docker ps --filter name=minio'
ssh t630@192.168.1.20 'curl -fsS --connect-timeout 3 http://192.168.1.19:19000/minio/health/live || echo LAN_NOT_READY'
```

## Wdrożenie (Ansible — po approval)

```bash
# G2 — przykład; dokładne tagi z SPEC-014B po implementacji
cd ~/repos/homeserver-services
APPROVE_DEPLOY=yes ansible-playbook playbooks/g2.yml -l g2 --tags restic-minio --check
APPROVE_DEPLOY=yes ansible-playbook playbooks/g2.yml -l g2 --tags restic-minio

# T630 — szablon credentials (wartości z Vault, nie z Git)
cd ~/repos/homeserver-core
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags restic-minio --check
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags restic-minio
```

## Weryfikacja

```bash
ssh g2@192.168.1.19 'set -a; . /opt/homeserver-services/g2-config/minio/.env; set +a; \
  mc alias set local http://192.168.1.19:19000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && \
  mc ls local/restic-backups'

# credentials.env jest root:600 — użyj sudo na T630
ssh t630@192.168.1.20 'sudo bash -c "set -a; . /etc/restic/credentials.env; set +a; \
  mc alias set g2restic http://192.168.1.19:19000 \"\$AWS_ACCESS_KEY_ID\" \"\$AWS_SECRET_ACCESS_KEY\" && \
  mc ls g2restic/restic-backups"'
```

## Rollback

- Przywróć `trading_minio_api_bind: "127.0.0.1"` i redeploy MinIO compose.
- Usuń użytkownika `restic-t630` przez `mc admin user remove` (jeśli utworzony).
- Bucket można zostawić pusty do czasu 014C.

## Następny krok

[SPEC-014C](../../specs/SPEC-014C-restic-init-first-backup.md) — `restic` na T630, init, pierwszy backup P0 — [runbook](t630-restic-first-backup.md).
