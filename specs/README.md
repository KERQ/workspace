# Specs — hierarchia pracy

## Flow

```text
BACKLOG → EPIC → SPEC → PROMPT → PATCH → TEST → REVIEW → ADR/RUNBOOK
```

## Kiedy EPIC, kiedy SPEC

| Sytuacja | Artefakt |
|----------|----------|
| Mała zmiana w jednym repo | **SPEC** |
| Plan obejmujący kilka repo lub wiele faz | **EPIC** + **child SPEC** |
| Agent w sesji | Realizuje **jeden SPEC** naraz |

EPIC koordynuje child SPECs, ale **nie jest** miejscem na implementację wszystkiego naraz.

## Szablony

- EPIC: [`epics/EPIC-000-template.md`](epics/EPIC-000-template.md)
- SPEC: [`SPEC-000-template.md`](SPEC-000-template.md)

## Wymagania każdego SPEC

Każdy SPEC musi zawierać:

- **Definition of Ready** — kiedy można zacząć
- **Definition of Done** — kiedy uznajemy za skończone
- **Test plan** — jak weryfikujemy
- **Rollback** — jak cofnąć
- **Prompt plan** — jak delegować agentowi

## EPIC w toku

- [`epics/EPIC-001-ai-native-workspace-foundation.md`](epics/EPIC-001-ai-native-workspace-foundation.md)

## Numeracja

- `EPIC-NNN` — epiki w `specs/epics/`
- `SPEC-NNN` lub `SPEC-NNNA-...` — specyfikacje w `specs/` (child SPECs mogą mieć sufiks literowy)

## Bez SPEC — bez implementacji

Jeśli nie ma zaakceptowanego SPEC, agent **proponuje SPEC** zamiast od razu pisać kod.
