# Workspace — AI-Native multi-repo

Wspólny kontekst pracy nad systemem domowym i research bez scalania repozytoriów w monorepo.

## Czym jest ten katalog

`~/repos/workspace/` łączy:

- **specs** — co i jak zmieniamy (EPIC, SPEC)
- **contracts** — techniczne umowy między repo
- **docs/adr** — decyzje architektoniczne
- **docs/runbooks** — procedury operacyjne
- **symlinki** — do pięciu repo domenowych (bez zmiany ich Git remote)

## Repozytoria

| Katalog | Opis |
|---------|------|
| `homeserver-core/` | Infra: Docker, Tailscale, Caddy, monitoring, backup |
| `homeserver-services/` | OpenClaw, LiteLLM, Paperclip, Airflow |
| `life-platform/` | Home Assistant, MQTT, Zigbee, ESPHome |
| `investment-research/` | ML / research (wysoka prywatność) |
| `openclaw-control-plane/` | Policy, agents, memory, governance |

## Gdzie szukać

| Potrzeba | Ścieżka |
|----------|---------|
| Cel i zasady projektu | [`PROJEKT.md`](PROJEKT.md) |
| Reguły agenta | [`AGENTS.md`](AGENTS.md) |
| Kolejka pracy | [`BACKLOG.md`](BACKLOG.md) |
| Specyfikacje | [`specs/`](specs/) |
| Kontrakty między repo | [`contracts/`](contracts/) |
| Decyzje architektoniczne | [`docs/adr/`](docs/adr/) |
| Procedury operacyjne | [`docs/runbooks/`](docs/runbooks/) |
| Checki diagnostyczne | [`scripts/checks/`](scripts/checks/) |
| Deploy orchestration | [`deploy/`](deploy/) |

## Jak zacząć pracę

1. Otwórz Cursor w **`~/repos/workspace`** (nie tylko w jednym repo).
2. Przeczytaj `PROJEKT.md` i `AGENTS.md`.
3. Sprawdź `BACKLOG.md` — wybierz element z sekcji **Now** lub **Next**.
4. Dla większej zmiany: utwórz lub otwórz **EPIC** w `specs/epics/`.
5. Dla implementacji: jeden **SPEC** w `specs/` (szablon: `SPEC-000-template.md`).
6. Po zatwierdzeniu SPEC → prompt → patch w repo domenowym → test → review.
7. W razie potrzeby: ADR lub runbook.

## Flow pracy

```text
BACKLOG → EPIC → SPEC → PROMPT → PATCH → TEST → REVIEW → ADR/RUNBOOK
```

## EPIC w toku

- [`specs/epics/EPIC-001-ai-native-workspace-foundation.md`](specs/epics/EPIC-001-ai-native-workspace-foundation.md) — Faza 1: fundament workspace (bez deployu).

## Uwaga o PLAN.md

[`PLAN.md`](PLAN.md) to starszy dokument eksploracyjny (meta-repo / submodules). Operacyjnie obowiązują **`PROJEKT.md`** i **`AGENTS.md`**.
