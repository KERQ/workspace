# Worklog: SPEC-007C — LibreChat deploy

**Data:** 2026-05-17  
**Status:** done

## Deploy

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags librechat
```

- Kontenery: `librechat`, `librechat-mongo` — Up
- Sekrety LibreChat dodane lokalnie w `host_vars/t630.yml` (nie w Git)

## Smoke

| Test | Wynik |
|------|--------|
| `http://127.0.0.1:3080/` | 200 |
| Caddy `http://127.0.0.1/chat/` | 200 |
| `https://t630.colobus-micro.ts.net/chat/` | 200 |

## Uwagi

- Pierwsza wizyta: rejestracja użytkownika (ALLOW_REGISTRATION=true).
- W UI wybrać endpoint **OpenClaw**, model `openclaw/default`.
- Test chat w przeglądarce — ręcznie (owner).
