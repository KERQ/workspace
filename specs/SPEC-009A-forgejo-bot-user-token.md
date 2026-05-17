# SPEC-009A: Forgejo — użytkownik `openclaw-bot` + tokeny

Parent: [EPIC-009](epics/EPIC-009-forgejo-bot.md)
Status: planned

## Zakres

1. Konto Forgejo **`openclaw-bot`** (bot, bez hasła logowania UI — tylko PAT).
2. PAT ze scope: **read** repo/PR + **write** issues/PR comments (status API jeśli osobny scope).
3. Sekrety w `inventory/host_vars/t630.yml` (gitignored):
   - `forgejo_bot_token`
   - `forgejo_webhook_secret` (losowy, min. 32 znaki)
4. Dokumentacja ręcznego kroku w runbooku (Forgejo UI → Settings → Applications).

## Poza zakresem

- Automatyczne tworzenie użytka przez Ansible (opcjonalnie później przez `forgejo admin` CLI).

## Smoke

- `curl` Forgejo API jako bot: `GET /api/v1/user` → 200, login `openclaw-bot`.
- Token **nie** może pushować do repo (403/401 na `POST` do contents).
