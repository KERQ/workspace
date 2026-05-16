# Runbook: migracja runtime path na G2 (EPIC-005 / SPEC-005B)

**Host:** `g2@192.168.1.19`  
**Cel:** `/opt/homeserver-services` jako kanon; symlinki wsteczne na stare ścieżki do Fazy 3 (Ansible).

## Wymagania

- Okno maintenance (~15–30 min na cutover)
- `APPROVE_DEPLOY=yes` tylko dla `cutover` / `rollback`
- Backup na `/mnt/seagate/backups/epic-005-g2-runtime-path/`
- Na G2: `sudo` bez hasła (grupa `sudo`); **brak `rsync`** — skrypt używa `cp -a`
- Utworzenie `/opt/homeserver-services` wymaga `sudo` (właściciel `g2:g2`)

## Sekwencja

Z Maca (workspace):

```bash
cd ~/repos/workspace
chmod +x scripts/migration/g2-runtime-path-migrate.sh deploy/scripts/migrate-g2-runtime-path.sh

./deploy/scripts/migrate-g2-runtime-path.sh preflight
./deploy/scripts/migrate-g2-runtime-path.sh backup
./deploy/scripts/migrate-g2-runtime-path.sh sync

# Krótka przerwa — cutover zatrzymuje stacki Docker
APPROVE_DEPLOY=yes ./deploy/scripts/migrate-g2-runtime-path.sh cutover --apply
./deploy/scripts/migrate-g2-runtime-path.sh smoke
```

## Po 005B (przed 005D)

- Fizyczne dane: `/opt/homeserver-services/`
- Docker nadal widzi: `/opt/homeserver-ansible-repo` → symlink
- Infisical: `/opt/homeserver-ansible/infisical` → symlink
- **Nie usuwać** `homeserver-ansible-repo.bak-*` do zakończenia 005D/E

## Rollback

```bash
APPROVE_DEPLOY=yes ./deploy/scripts/migrate-g2-runtime-path.sh rollback --apply
```

## Kryteria sukcesu

- [ ] `readlink -f /opt/homeserver-ansible-repo` = `/opt/homeserver-services`
- [ ] LiteLLM, Airflow, MinIO health OK
- [ ] `scripts/trading/smoke.sh` PASS (opcjonalnie)
- [ ] Infisical UI `:8081` dostępny

## Następny krok

**SPEC-005D:** zmiana `homeserver_runtime_root` w Ansible na `/opt/homeserver-services` + deploy.
