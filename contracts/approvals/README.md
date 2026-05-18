# Contracts: approvals (EPIC-010)

Źródło prawdy dla **approval-first task workflow** na T630. Implementacja: SPEC-010A–010E.

## Pliki

| Plik | Rola |
|------|------|
| [`task-states.yml`](task-states.yml) | Dozwolone stany i przejścia |
| [`events.yml`](events.yml) | Typy zdarzeń (`events.jsonl`) |
| [`gates.yml`](gates.yml) | Bramki approval vs akcje Git/PR |
| [`enforcement.yml`](enforcement.yml) | Warstwy obrony + mapowanie gate → skrypty/polityki |
| [`task-artifact.example.json`](task-artifact.example.json) | Przykład `task.json` |

## Runtime (T630)

```text
/srv/worktrees/.tasks/<task-id>/
  task.json       # stan bieżący
  events.jsonl    # historia (append-only)
  test.log        # opcjonalnie
```

Worktree: `/srv/worktrees/<repo>-<task-id>/` (EPIC-008).

## Zasady

- **Trzy** osobne `approval_granted` (`diff_review`, `commit`, `push_pr`).
- **Merge** — tylko człowiek w Forgejo; brak gate `merge`.
- **Brak sekretów** w artefaktach taska.
- **openclaw-bot** nie wykonuje push (EPIC-009).

## Powiązane

- [SPEC-010A](../../specs/SPEC-010A-approval-state-contracts.md)
- [EPIC-010](../../specs/epics/EPIC-010-approval-pr-flow.md)
- [PROJEKT.md](../../PROJEKT.md) — § approval-first
