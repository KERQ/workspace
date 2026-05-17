# SPEC-015 — 2026-05-17 — T630/G2 service dashboard audit

## Cel sesji

Zrealizować backlogowy przegląd usług T630/G2 i przygotować one-pager pokazujący linki webowe, porty i status usług. Celem pośrednim było zrozumienie problemu Caddy przed dalszą pracą nad Forgejo.

## Kontekst

- SPEC: [SPEC-015](../../../specs/SPEC-015-t630-g2-service-dashboard.md)
- Dashboard: [T630/G2 Service Dashboard](../../runbooks/t630-g2-service-dashboard.md)
- Poprzedni sygnał: [SPEC-014A](../../../specs/SPEC-014A-t630-disk-reclaim-phase0.md) wykrył `caddy` container restart loop na T630.

## Wykonane

- Zebrano read-only stan T630:
  - `df -h`
  - `ss -lntp`
  - `docker ps`
  - `systemctl --failed`
  - `systemctl status caddy`
  - user services
  - HTTP smoke checks
- Zebrano read-only stan G2:
  - `df -h`
  - `ss -lntp`
  - `docker ps`
  - `systemctl --failed`
  - HTTP smoke checks
- Porównano lokalną konfigurację `life-platform` compose z faktycznym stanem hosta.
- Utworzono one-pager operacyjny.

## Testy / komendy

| Krok | Wynik |
|------|-------|
| T630 `systemctl --failed` | 0 failed units |
| G2 `systemctl --failed` | 0 failed units |
| T630 `docker ps` | Główne kontenery up; `caddy` i `timescaledb` restarting |
| G2 `docker ps` | Główne kontenery up; Caddy up |
| T630 HTTP smoke | HA/Zigbee/ESPHome/OpenClaw Studio/ClawSuite OK; Paperclip redirect |
| G2 HTTP smoke | Caddy/Grafana/Uptime/Infisical/Plane/MinIO/Ollama odpowiadają |

## Wyniki

- Dashboard zapisany w `docs/runbooks/t630-g2-service-dashboard.md`.
- T630:
  - hostowy `caddy.service` działa i zajmuje `*:80`,
  - kontener `caddy` z `life-platform` działa w `network_mode: host` i przez to restartuje się na konflikcie `:80`,
  - `openclaw-studio`, `clawsuite`, `paperclip` działają jako user services.
- G2:
  - Caddy działa poprawnie jako kontener,
  - MinIO local (`127.0.0.1:19000/19001`) jest dobrym kandydatem dla EPIC-014B,
  - `/mnt/seagate` ma ~21T wolne.

## Problemy / ryzyka

- T630 ma dwa modele Caddy naraz:
  - systemd `caddy.service` (`/etc/caddy/Caddyfile`),
  - Docker `caddy` z `life-platform` (`network_mode: host`).
- Forgejo nie powinno wejść na T630, dopóki reverse proxy nie ma jednego właściciela.
- `timescaledb` na T630 jest w restart loop; do osobnej oceny, jeśli nadal jest potrzebny.

## Commity

- Do uzupełnienia po commit/push SPEC-015.

## Follow-up

- [ ] SPEC dla Caddy T630: zdecydować `systemd caddy` vs `docker caddy`.
- [ ] EPIC-014B: MinIO bucket + dostęp Restic z T630.
- [ ] Dodać automatyczny check portów/dashboard później, jeśli one-pager zacznie się dezaktualizować.
