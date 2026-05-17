# Worklog: SPEC-007B — Caddy `/chat/` + audyt `/v1`

**Data:** 2026-05-17  
**SPEC:** [SPEC-007B](../../specs/SPEC-007B-openclaw-caddy-ingress.md)  
**Status:** draft — Caddyfile w repo; deploy Caddy **pending** (`APPROVE_DEPLOY`)

## Zmiany w repo

- `life-platform`: `domains/home/configs/caddy/Caddyfile` — `/chat` → `127.0.0.1:3080`
- `workspace`: SPEC-007B, runbook szkic, ten worklog

## Audyt `/v1` (powtórzenie 007A)

| Test | Status | Uwagi |
|------|--------|-------|
| `/v1/models` + Bearer | PASS | 007A |
| `/v1/models` bez auth | PASS | 401 |
| `/openclaw/` | PASS | 200 |

## Smoke `/chat` (po deploy Caddy)

| Test | Status | Uwagi |
|------|--------|-------|
| `curl …/chat/` tailnet | pending | Oczekiwane 502 do 007C |
| Regresja `/git/`, `/clawsuite/` | pending | Po deploy |

## Deploy

- [ ] `APPROVE_DEPLOY=yes` → recreate `caddy` na T630
