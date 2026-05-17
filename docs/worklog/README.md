# Worklog

Dziennik wykonania prac dla EPIC/SPEC. To miejsce na podsumowania sesji agenta i człowieka: co zostało zrobione, jakie komendy/testy uruchomiono, jakie były wyniki, które commity powstały i jakie follow-upy zostały odkryte.

## Dlaczego osobno od SPEC/EPIC

- `SPEC` i `EPIC` są kontraktem pracy: cel, zakres, test plan, DoD, rollback.
- `docs/worklog/` jest historią wykonania: przebieg sesji, wyniki komend, problemy i decyzje operacyjne.
- `docs/runbooks/` pozostają miejscem na powtarzalne procedury.
- `docs/adr/` pozostają miejscem na trwałe decyzje architektoniczne.

## Struktura

```text
docs/worklog/
├── README.md
├── EPIC-014/
│   └── SPEC-014A-2026-05-17-t630-disk-reclaim.md
└── EPIC-006/
    └── ...
```

## Nazewnictwo

```text
docs/worklog/EPIC-NNN/SPEC-NNNA-YYYY-MM-DD-krotki-slug.md
docs/worklog/EPIC-NNN/EPIC-NNN-YYYY-MM-DD-krotki-slug.md
```

Przykłady:

```text
docs/worklog/EPIC-014/SPEC-014A-2026-05-17-t630-disk-reclaim.md
docs/worklog/EPIC-006/EPIC-006-2026-05-18-forgejo-design-review.md
```

## Kiedy aktualizować

- Po zakończeniu SPEC albo większego kroku w SPEC.
- Po sesji operacyjnej na hoście (deploy, cleanup, backup, restore drill, smoke test).
- Po odkryciu istotnego ryzyka lub follow-upu.
- Po commitach/pushach związanych z pracą.

Nie trzeba tworzyć logu dla drobnych poprawek literówek bez wpływu na flow.

## Minimalny szablon

```markdown
# SPEC-NNNA — YYYY-MM-DD — Tytuł

## Cel sesji

Co miało zostać osiągnięte.

## Kontekst

- Parent: [EPIC-...](../../specs/epics/...)
- SPEC: [SPEC-...](../../specs/...)

## Wykonane

- ...

## Testy / komendy

| Krok | Wynik |
|------|-------|
| ... | ... |

## Wyniki

- ...

## Problemy / ryzyka

- ...

## Commity

- `repo`: `sha` — opis

## Follow-up

- [ ] ...
```

## Linkowanie z SPEC/EPIC

W każdym zakończonym lub aktywnym SPEC/EPIC dodaj sekcję:

```markdown
## Work log

- [YYYY-MM-DD — krótki opis](../docs/worklog/EPIC-NNN/...)
```
