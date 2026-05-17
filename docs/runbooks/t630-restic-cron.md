# Runbook: T630 — Restic cron i backup-all (SPEC-014D)

Wymaga [SPEC-014C](t630-restic-first-backup.md) (init repo).

## Codzienny harmonogram

| Czas | Job |
|------|-----|
| 02:30–03:45 | Lokalne backupy (`backup-ha`, `backup-openclaw`, …) |
| **04:30** | `restic-backup-all.sh` → MinIO G2 |

## Ręczny run

```bash
ssh t630@192.168.1.20 'sudo /usr/local/bin/restic-backup-all.sh'
# lub w tle:
ssh t630@192.168.1.20 'sudo nohup /usr/local/bin/restic-backup-all.sh </dev/null &>/tmp/restic-all.nohup.out &'
```

Log: `/var/log/restic/backup-all-*.log`

## Weryfikacja

```bash
ssh t630@192.168.1.20 'sudo crontab -l | grep -i restic'

ssh t630@192.168.1.20 'sudo bash -c "
  set -a; . /etc/restic/credentials.env; set +a
  export AWS_S3_FORCE_PATH_STYLE=true
  restic snapshots
"'
```

## Retencja

`forget --prune`: 7 daily, 4 weekly, 6 monthly (zmienne `restic_forget_*` w Ansible).

## Deploy Ansible

```bash
cd ~/repos/homeserver-core
ansible-playbook playbooks/t630.yml -l t630 --tags restic-cron --syntax-check
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags restic-cron,restic-minio,restic
```

## Następny krok

[SPEC-014E](../specs/SPEC-014E-restic-restore-retention.md) — restore drill + skrócenie lokalnej retencji.
