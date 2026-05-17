# Plan rozwoju OpenClaw (EPIC-007) — post archiwum EPIC-OCP-1

**Status:** accepted (po audycie SPEC-007A, 2026-05-17)  
**Data:** 2026-05-17  
**Owner:** karolkurek  
**Worklog:** [SPEC-007A audyt](../worklog/EPIC-007/SPEC-007A-2026-05-17-openclaw-audit.md)

## 1. Decyzja strategiczna

| Element | Stan |
|---------|------|
| EPIC-OCP-1 (`apps/ui`, `apps/api`) | **Zarchiwizowany** — bez nowych feature’ów |
| UI delegacji (chat) | **LibreChat** (MVP), opcjonalnie **LobeChat** |
| OpenClaw Gateway `/v1` | Kanoniczny endpoint dla UI i integracji |
| Reinstall OpenClaw | **Nie** w EPIC-007 |

ADR: `openclaw-control-plane/docs/adr/2026-05-17-archive-epic-ocp-1-librechat-delegation-ui.md`

## 2. Podział repozytoriów

| Odpowiedzialność | Repo | Ścieżki / artefakty |
|------------------|------|---------------------|
| Agenci, polityki, projekty | `openclaw-control-plane` | `agents/`, `policies/`, `projects/`, `config/` |
| Render / walidacja | `openclaw-control-plane` | `scripts/stage-config.py`, `validate-policies.py` |
| Runtime deploy (T630) | `homeserver-services` | `roles/openclaw`, `roles/openclaw-studio`, `playbooks/t630.yml` |
| LibreChat (nowe) | `homeserver-services` | `roles/librechat/` *(007C)* |
| Ingress tailnet | `life-platform` | `domains/home/configs/caddy/Caddyfile` |
| Plany, runbooki, kontrakty | `workspace` | `specs/`, `docs/runbooks/`, `contracts/services/ports.yml` |
| Zamrożone (referencja) | `openclaw-control-plane` | `apps/ui/`, `apps/api/` |

**Nie tworzymy** nowego repo `openclaw-gateway`.

## 3. Workflow zmian (config → runtime)

```text
1. Edycja agents/policies/config w openclaw-control-plane
2. python3 scripts/validate-policies.py
3. python3 scripts/stage-config.py --validate-only
4. python3 scripts/stage-config.py  →  review build/openclaw/
5. Approval (karolkurek)
6. APPROVE_DEPLOY=yes → ansible-playbook playbooks/t630.yml -l t630 --tags openclaw [-e openclaw_enabled=true]
7. openclaw doctor (jeśli dostępne) + smoke /v1
8. Worklog w workspace/docs/worklog/EPIC-007/
```

Sekrety: Infisical → `homeserver-services/inventory/host_vars/t630.yml` (git-crypt) — nigdy w `openclaw-control-plane` commit plaintext.

## 4. Warstwy runtime na T630

| Warstwa | Port / ścieżka | Rola |
|---------|----------------|------|
| OpenClaw Gateway | `127.0.0.1:18789` | systemd, `/v1`, control UI `/openclaw` |
| Caddy (Docker) | `:80` → proxy | `/v1*`, `/openclaw*`, `/git/*` |
| Tailscale Serve | → Caddy :80 | Dostęp tailnet |
| LibreChat | `:3080` *(plan)* | UI delegacji → gateway `/v1` |
| LiteLLM | G2 `:4000` | Modele agentów (bez zmian w 007) |
| OCP stack *(audyt)* | TBD | Postgres/UI — rekomendacja stop w 007E |

## 5. LibreChat vs OCP UI

| Funkcja | OCP `apps/ui` (archiwum) | LibreChat (007C) |
|---------|--------------------------|------------------|
| Chat do agenta | `/chat` | Główny flow |
| Sessions / tasks / approvals | Wbudowane w OCP | Poza MVP — OpenClaw + Forgejo + EPIC-010 później |
| Memory w UI | Hybryda OCP | **OFF** — tylko OpenClaw workspace |
| Koszty / dashboard | OCP API | Poza MVP 007 |

## 6. Kolejność implementacji (SPECs)

```text
007A  audyt + ten plan (uzupełnienie sekcji 7)
007B  Caddy: /v1 audit + /chat ingress
007C  LibreChat compose + librechat.yaml → openclaw/default
007D  LobeChat (opcjonalnie)
007E  tool policies, runbook, contracts, decommission OCP runtime
```

## 7. Wyniki audytu (SPEC-007A, 2026-05-17)

| Obszar | Status | Uwagi |
|--------|--------|-------|
| Gateway systemd | **OK** | OpenClaw 2026.5.3-1, `127.0.0.1:18789` |
| `/v1` smoke loopback | **PASS** | models + chat `openclaw/default` |
| `/v1` smoke tailnet | **PASS** | przez `t630.colobus-micro.ts.net` |
| Auth Bearer wymagany | **TAK** | 401 bez tokena (loopback i tailnet) |
| Config drift Ansible vs runtime | **Niski** | auth + chatCompletions włączone; pełny diff pominięty |
| OCP kontenery na T630 | **Częściowe** | Postgres + Redis; **brak** UI/API |
| `openclaw_enabled` w inventory | **true** | `host_vars/t630.yml` |

Inne porty: 3000 OpenClaw Studio (**loopback only**), 3002 ClawSuite, 3030 Forgejo — **3080** LibreChat (Caddy `/chat/` w 007B).

## 8. Rekomendacja OCP runtime na T630

**Rekomendacja:** **(b) stop compose** `openclaw-control-plane-postgres` + `openclaw-control-plane-redis` w **SPEC-007E**, po udanym smoke LibreChat (007C). UI/API OCP i tak nie działają — zostają tylko DB/cache bez konsumenta.

**Nie usuwać** wolumenów w 007E bez osobnego backupu/approval. **Nie** restartować `openclaw-gateway` w ramach audytu.

## 9. URL-e ingress (SPEC-007B)

| Usługa | URL |
|--------|-----|
| Gateway UI | `https://t630.colobus-micro.ts.net/openclaw/` |
| API `/v1` | `https://t630.colobus-micro.ts.net/v1/` (+ Bearer) |
| ClawSuite | `https://t630.colobus-micro.ts.net/clawsuite/` — **nie** `:3002` bez Caddy |
| LibreChat | `https://t630.colobus-micro.ts.net/chat/` → `127.0.0.1:3080` |
| Forgejo | `https://t630.colobus-micro.ts.net/git/` |
| OpenClaw Studio | `127.0.0.1:3000` na hoście lub tunel SSH |
