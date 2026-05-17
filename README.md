# Workspace — AI-Native multi-repo

Wspólny kontekst pracy nad systemem domowym i research bez scalania repozytoriów w monorepo.

## Czym jest ten katalog

`~/repos/workspace/` łączy:

- **specs** — co i jak zmieniamy (EPIC, SPEC)
- **docs/ideas** — analizy i rozpisane pomysły przed backlogiem
- **docs/worklog** — dziennik wykonania prac SPEC/EPIC
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
| Analizy przed backlogiem | [`docs/ideas/`](docs/ideas/) |
| Kolejka pracy | [`BACKLOG.md`](BACKLOG.md) |
| Specyfikacje | [`specs/`](specs/) |
| Log wykonania SPEC/EPIC | [`docs/worklog/`](docs/worklog/) |
| Kontrakty między repo | [`contracts/`](contracts/) |
| Decyzje architektoniczne | [`docs/adr/`](docs/adr/) |
| Procedury operacyjne | [`docs/runbooks/`](docs/runbooks/) |
| Checki diagnostyczne | [`scripts/checks/`](scripts/checks/) |
| Deploy orchestration | [`deploy/`](deploy/) |

## Jak zacząć pracę

1. Otwórz Cursor w **`~/repos/workspace`** (nie tylko w jednym repo).
2. Przeczytaj `PROJEKT.md` i `AGENTS.md`.
3. Jeśli pomysł jest jeszcze luźny, opisz go w `docs/ideas/`.
4. Sprawdź `BACKLOG.md` — wybierz element z sekcji **Now** lub **Next**.
5. Dla większej zmiany: utwórz lub otwórz **EPIC** w `specs/epics/`.
6. Dla implementacji: jeden **SPEC** w `specs/` (szablon: `SPEC-000-template.md`).
7. Po zatwierdzeniu SPEC → prompt → patch w repo domenowym → test → review.
8. Po zakończeniu pracy dopisz wpis w `docs/worklog/` i link w SPEC/EPIC.
9. W razie potrzeby: ADR lub runbook.

## Flow pracy

```text
IDEA → BACKLOG → EPIC → SPEC → PROMPT → PATCH → TEST → REVIEW → WORKLOG → ADR/RUNBOOK
```

## Najbliższe EPIC

Aktualna kolejka jest w [`BACKLOG.md`](BACKLOG.md). Priorytet: [`EPIC-014`](specs/epics/EPIC-014-restic-minio-offbox-backup.md) (miejsce na dysku + Restic/MinIO), potem [`EPIC-006`](specs/epics/EPIC-006-forgejo-mvp.md) (Forgejo).

## Uwaga o PLAN.md

[`PLAN.md`](PLAN.md) to starszy dokument eksploracyjny (meta-repo / submodules). Operacyjnie obowiązują **`PROJEKT.md`** i **`AGENTS.md`**.
