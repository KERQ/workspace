# Runbook: T630 — Restic init i pierwszy backup P0 (SPEC-014C)

Wymaga ukończonego [SPEC-014B](g2-minio-restic-backend.md). **Nie** skraca lokalnej retencji `/opt/backups`.

## Wymagania

- `/etc/restic/credentials.env` (mode `600`) z `RESTIC_REPOSITORY`, `AWS_*`
- `RESTIC_PASSWORD` ustawione (init) — poza Git
- MinIO: `curl http://192.168.1.19:19000/minio/health/live` z T630 → OK

## 1. Deploy roli Ansible

```bash
cd ~/repos/homeserver-core
ansible-playbook playbooks/t630.yml -l t630 --tags restic --syntax-check
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags restic
```

## 2. Init repozytorium (jednorazowo)

**Hasło nieodwracalne bez kopii recovery.**

```bash
ssh -t t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  export AWS_S3_FORCE_PATH_STYLE=true; \
  restic init'
```

Oczekiwane: `created restic repository` lub informacja że repo już istnieje.

## 3. Pierwszy backup P0 (`/opt/backups`)

Uruchom w oknie maintenance (może trwać długo):

```bash
ssh t630@192.168.1.20 'sudo /usr/local/bin/restic-backup-p0.sh'
```

Alternatywa ad-hoc:

```bash
ssh t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  export AWS_S3_FORCE_PATH_STYLE=true; \
  restic backup /opt/backups --tag t630-backups \
    --exclude-file /etc/restic/excludes.txt -v'
```

## 4. Weryfikacja

```bash
ssh t630@192.168.1.20 'set -a; . /etc/restic/credentials.env; set +a; \
  export AWS_S3_FORCE_PATH_STYLE=true; \
  restic snapshots --tag t630-backups; restic check'
```

## 5. G2 — rozmiar w bucket

```bash
ssh g2@192.168.1.19 'set -a; . /opt/homeserver-services/g2-config/minio/.env; set +a; \
  mc alias set local http://127.0.0.1:19000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && \
  mc du local/restic-backups'
```

## Rollback

- Nie usuwaj `/opt/backups` lokalnie.
- Usunięcie repo MinIO tylko w środowisku testowym (`mc rm --recursive`).

## Następny krok

[SPEC-014D](../../specs/SPEC-014D-restic-cron-paths.md) — cron i pozostałe zestawy.
