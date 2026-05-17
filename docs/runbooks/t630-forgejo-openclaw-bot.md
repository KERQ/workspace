# Runbook: T630 — Forgejo `openclaw-bot` (konto + PAT + sekrety)

**EPIC:** [EPIC-009](../../specs/epics/EPIC-009-forgejo-bot.md)  
**SPEC:** [SPEC-009A](../../specs/SPEC-009A-forgejo-bot-user-token.md)  
**Status:** 009A–009C done; 009D (status check + pełny smoke PR) — w toku

## Kontekst

| Element | Wartość (T630, zweryfikowane) |
|---------|------------------------------|
| Forgejo API (loopback) | `http://127.0.0.1:3030` |
| Forgejo UI (tailnet) | `https://t630.colobus-micro.ts.net/git/` |
| Org pilotażowa | `KERQ` |
| Repo pilotażowe | `KERQ/homeserver-services` (private) |
| Użytkownik bota | `openclaw-bot` |
| OpenClaw (009C) | `http://127.0.0.1:18789/v1/chat/completions` |

**Guardrails:** bot **nie** pushuje do repo, **nie** merge’uje, **nie** deployuje. Token tylko read PR + komentarze (status check — osobny scope w 009C/009D jeśli potrzebny).

## Preflight

```bash
ssh t630@192.168.1.20 '
  ss -lntp | grep ":3030"
  curl -sS -o /dev/null -w "forgejo: %{http_code}\n" http://127.0.0.1:3030/
  curl -sS http://127.0.0.1:3030/api/v1/version | jq -r ".version"
'
```

Oczekiwane: port `127.0.0.1:3030` LISTEN, HTTP 200/302, wersja Forgejo w JSON.

Sprawdzenie, czy konto bota już istnieje (bez tokenu — publiczny endpoint):

```bash
ssh t630@192.168.1.20 \
  'curl -sS -o /dev/null -w "openclaw-bot: %{http_code}\n" http://127.0.0.1:3030/api/v1/users/openclaw-bot'
```

`404` = konto do utworzenia. `200` = konto jest — przejdź do PAT / smoke.

---

## 1. Utworzenie użytkownika `openclaw-bot` (Forgejo UI)

Wymaga konta **admina** (rejestracja publiczna jest wyłączona na T630).

1. Otwórz `https://t630.colobus-micro.ts.net/git/` i zaloguj się jako admin.
2. **Site administration** → **User accounts** → **Create user account**.
3. Pola:
   - **Username:** `openclaw-bot`
   - **Email:** np. `openclaw-bot@local` (unikalny w instancji)
   - **Password:** wygeneruj silne hasło (menedżer haseł); **nie** udostępniaj agentom — bot korzysta wyłącznie z PAT.
   - Opcjonalnie: **Must change password** — wyłączone; konto nie loguje się do UI na co dzień.
4. Zapisz użytkownika.

### Członkostwo w org `KERQ`

1. **Organizations** → `KERQ` → **Members** (lub **Teams**).
2. Dodaj `openclaw-bot` do org (rola z dostępem **read** do repo `homeserver-services` — np. członek zespołu z dostępem do repozytoriów org).
3. Upewnij się, że `openclaw-bot` widzi `KERQ/homeserver-services` w UI (Settings → Repositories lub lista org).

---

## 2. Personal Access Token (PAT)

Zaloguj się **jako `openclaw-bot`** (jednorazowo, tylko do wygenerowania tokenu) albo użyj sudo admina zgodnie z polityką instancji.

1. **Settings** (ikona użytkownika) → **Applications** → **Generate New Token**.
2. **Token name:** np. `openclaw-bot-mvp` (data w nazwie pomaga rotacji).
3. **Repository and organization access:** **Specific repositories** → wybierz tylko `KERQ/homeserver-services` (najwęższy dostęp).
4. **Scopes** (MVP — zgodnie z [Forgejo token scope](https://forgejo.org/docs/latest/user/token-scope/)):

   | Scope | Po co |
   |-------|--------|
   | `read:repository` | Odczyt PR, diff, metadanych repo |
   | `read:issue` | Odczyt komentarzy issue/PR |
   | `write:issue` | Komentarze na PR (`/openclaw …`) |

   **Nie zaznaczaj** w MVP:
   - `write:repository` (push plików, tworzenie PR przez API — poza polityką bota)
   - `write:admin`, `write:organization`, `write:user`, itd.

   **Uwaga (009C/009D):** status check `OpenClaw Review` (`POST …/statuses/{sha}`) może wymagać dodatkowego scope — prawdopodobnie `write:repository` na wybranym repo. Dodaj go dopiero po smoke negatywnym na zapis plików i świadomej akceptacji ryzyka; alternatywa: osobny token tylko do statusów.

5. **Generate token** — skopiuj token **od razu** (Forgejo nie pokaże go ponownie).

---

## 3. Webhook secret (placeholder na host_vars)

Sekret służy do weryfikacji HMAC webhooków Forgejo → bot (`8091`, [SPEC-009B](../../specs/SPEC-009B-forgejo-bot-service-webhook.md)). **Ten sam ciąg** trafia do Forgejo (konfiguracja webhooka w repo) i do Ansible.

Wygeneruj lokalnie (min. 32 znaki hex = 64 znaki):

```bash
openssl rand -hex 32
```

Zapisz wynik jako `forgejo_webhook_secret` — **nie** commituj do Git.

Webhook URL (009B): `https://t630.colobus-micro.ts.net/forgejo-bot/hooks` — rejestracja przez Ansible lub Forgejo UI.

---

## 4. Sekrety w `inventory/host_vars/t630.yml`

Plik: `homeserver-services/inventory/host_vars/t630.yml` — **gitignored**, wartości **poza repozytorium** (Infisical export / ręcznie na Macu operatora).

Wymagane klucze (009A):

```yaml
# --- EPIC-009 / SPEC-009A (nie commitować wartości) ---
forgejo_bot_token: "<PAT z Forgejo UI — Applications>"
forgejo_webhook_secret: "<openssl rand -hex 32 — min. 32 bajty losowe>"
```

| Klucz | Opis |
|-------|------|
| `forgejo_bot_token` | PAT użytkownika `openclaw-bot` (nagłówek `Authorization: token …`) |
| `forgejo_webhook_secret` | Wspólny sekret webhooka Forgejo ↔ bot; min. 32 znaki losowe |

Dla 009C wymagany jest także `openclaw_gateway_token` (Bearer do OpenClaw `/v1`).

Istniejące klucze w tym pliku (np. `forgejo_db_password`) **nie usuwaj** — dopisz powyższe.

Polityka sekretów: [`contracts/secrets/scopes.yml`](../../contracts/secrets/scopes.yml) (`forgejo_bot_token` w `homeserver-services`).

**Nie** dodawaj tych wartości do `inventory/group_vars/*.yml` ani do commitowanych plików w Git.

---

## 5. Smoke (curl na T630)

Uruchom na T630 po uzupełnieniu `host_vars` (token w zmiennej środowiskowej — **nie** w historii shella na współdzielonym hoście, jeśli to problem):

```bash
ssh t630@192.168.1.20 bash -s <<'EOF'
set -euo pipefail
: "${FORGEJO_BOT_TOKEN:?ustaw FORGEJO_BOT_TOKEN (z host_vars, nie commituj)}"
BASE="http://127.0.0.1:3030"
AUTH="Authorization: token ${FORGEJO_BOT_TOKEN}"

echo "== GET /api/v1/user =="
curl -sS "${BASE}/api/v1/user" -H "${AUTH}" | jq '{id, login, is_admin}'

echo "== GET repo KERQ/homeserver-services =="
curl -sS -o /dev/null -w "repo: %{http_code}\n" \
  "${BASE}/api/v1/repos/KERQ/homeserver-services" -H "${AUTH}"

echo "== NEGATIVE: POST contents (musi być 401/403/404, NIE 201) =="
curl -sS -o /dev/null -w "post contents: %{http_code}\n" \
  -X POST "${BASE}/api/v1/repos/KERQ/homeserver-services/contents/README.md" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{"message":"openclaw-bot-smoke","content":"dGVzdA==","branch":"main"}'
EOF
```

Kryteria sukcesu (009A):

| Test | Oczekiwany wynik |
|------|------------------|
| `GET /api/v1/user` | HTTP 200, `"login": "openclaw-bot"` |
| `GET …/repos/KERQ/homeserver-services` | HTTP 200 |
| `POST …/contents/…` | HTTP **401**, **403** lub **404** — **nie** 201 |

Opcjonalnie — odczyt PR (jeśli istnieje PR #1):

```bash
curl -sS -o /dev/null -w "pulls/1: %{http_code}\n" \
  "http://127.0.0.1:3030/api/v1/repos/KERQ/homeserver-services/pulls/1" \
  -H "Authorization: token ${FORGEJO_BOT_TOKEN}"
```

---

## 6. Rotacja i awarie

| Problem | Działanie |
|---------|-----------|
| PAT wyciekł | Forgejo → Settings → Applications → usuń token → wygeneruj nowy → zaktualizuj `forgejo_bot_token` w `host_vars` |
| Webhook secret wyciekł | Nowy `openssl rand -hex 32` → `forgejo_webhook_secret` + zaktualizuj webhook w repo (009B) |
| `403` na repo | Sprawdź członkostwo `openclaw-bot` w org `KERQ` i scope „Specific repositories” |
| `201` na POST contents | **Natychmiast** unieważnij PAT — ma za szerokie scope (`write:repository`) |

---

## 7. Deploy 009B (serwis + Caddy)

```bash
# Bot (homeserver-services)
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags forgejo-bot

# Caddy ingress (life-platform)
cd life-platform/domains/home/ansible
ansible-playbook playbooks/t630.yml -l t630 --tags caddy
```

Smoke:

```bash
ssh t630 'curl -sS http://127.0.0.1:8091/health | jq .'
ssh t630 'docker logs openclaw-forgejo-bot --tail 20'
# Forgejo → repo → Settings → Webhooks — delivery 200 (po evencie PR/komentarz)
```

---

## 8. Deploy 009C (komendy + OpenClaw)

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags forgejo-bot \
  -e forgejo_bot_force_rebuild=true
```

W `host_vars/t630.yml` (nie commitować): `openclaw_gateway_token` obok `forgejo_bot_token` i `forgejo_webhook_secret`.

### Komendy w PR

| Komentarz | Efekt |
|-----------|--------|
| `/openclaw summarize` | Podsumowanie PR |
| `/openclaw review` | Code review |
| `/openclaw review tests` | Review testów |
| `/openclaw review privacy` | Sekrety / PII |

Bot ignoruje własne komentarze i komentarze na zwykłych issue (bez `pull_request`).

### Smoke 009C

```bash
ssh t630@192.168.1.20 'curl -sS http://127.0.0.1:8091/health | jq .'
# Oczekiwane: "version": "0.2.0"
```

Na żywym PR: dodaj komentarz `/openclaw summarize` → w ciągu ~2 min komentarz od `openclaw-bot`.

Alternatywa (zamknięty PR #1): symulacja webhooka z podpisem HMAC — patrz [worklog SPEC-009C](../worklog/EPIC-009/SPEC-009C-2026-05-17-forgejo-bot-commands.md).

Zmienne (`.env` bota): `FORGEJO_BOT_AUTO_SUMMARY=0` (domyślnie), `FORGEJO_BOT_DIFF_MAX_CHARS=80000`, `OPENCLAW_MODEL=openclaw/default`.

---

## Następny krok

- [SPEC-009D](../../specs/SPEC-009D-forgejo-bot-smoke-runbook.md): status check `OpenClaw Review`, pełny smoke PR, contracts.

Powiązane: [t630-forgejo-deploy.md](t630-forgejo-deploy.md), [t630-openclaw-gateway-librechat.md](t630-openclaw-gateway-librechat.md).
