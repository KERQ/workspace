# Ideas

Inkubator analiz, szkiców architektonicznych i rozpisanych pomysłów, które nie są jeszcze gotowe na `BACKLOG.md`.

## Kiedy używać

- Pomysł jest większy niż pojedynczy punkt w backlogu.
- Trzeba zebrać kontekst, warianty albo ryzyka przed decyzją.
- Nie wiadomo jeszcze, czy praca powinna zostać EPIC, SPEC, ADR czy runbookiem.
- Dokument pochodzi z rozmowy, researchu lub analizy i wymaga późniejszej syntezy.

## Kiedy przenieść do backlogu

Pomysł trafia do `BACKLOG.md`, gdy ma:

- jasny cel,
- właścicielski obszar lub repo,
- przybliżony zakres,
- ryzyka i guardrails,
- następny konkretny krok.

## Nazewnictwo

Używaj nazw z datą i krótkim slugiem:

```text
YYYY-MM-DD-krotki-slug.md
```

Przykłady (dokumenty źródłowe w tym katalogu):

- [`ai_native_workspace_plan.md`](ai_native_workspace_plan.md)
- [`openclaw_architektura_forgejo_github_backup.md`](openclaw_architektura_forgejo_github_backup.md)
- [`ai_driven_worflow.md`](ai_driven_worflow.md)

Nowe analizy nadal warto nazywać z datą:

```text
2026-05-17-krotki-slug.md
```

## Minimalny szablon

```markdown
# Tytuł

## Status

idea | ready-for-backlog | promoted | rejected

## Źródło

Link do rozmowy, dokumentu lub notatek.

## Problem

Co próbujemy rozwiązać.

## Propozycja

Krótki opis kierunku.

## Ryzyka / guardrails

Co może pójść źle i czego nie wolno robić.

## Kandydaci do BACKLOG

- [ ] EPIC/SPEC/TASK do rozważenia.

## Decyzja

Co robimy dalej albo dlaczego odkładamy.
```
