# Worklog: SPEC-007B — Caddy `/chat/` + audyt `/v1`

**Data:** 2026-05-17  
**SPEC:** [SPEC-007B](../../specs/SPEC-007B-openclaw-caddy-ingress.md)  
**Status:** done — Caddy wdrożony 2026-05-17 (`APPROVE_DEPLOY=yes`)

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
| `curl …/chat/` tailnet | **PASS** | **502** — LibreChat jeszcze nie działa (OK przed 007C) |
| `curl …/chat` → redirect | **PASS** | 200 |
| Regresja `/git/` | **PASS** | 200 |
| Regresja `/clawsuite/` | **PASS** | 307 |
| Regresja `/openclaw/` | **PASS** | 200 |
| `/v1/models` bez auth | **PASS** | 401 |

## Deploy

- [x] `APPROVE_DEPLOY=yes` — `ansible-playbook playbooks/t630.yml -l t630 --tags caddy` (life-platform); kontener `caddy` recreated
