# SPEC-010A: Stany taska + kontrakty approval

Parent: [EPIC-010](epics/EPIC-010-approval-pr-flow.md)
Status: draft
Repo: workspace
Owner: karolkurek
Risk: low (tylko kontrakty i dokumentacja; implementacja skryptów → 010C/010D)
Zablokowany przez: brak (epik zaakceptowany)
Blokuje: [SPEC-010B](SPEC-010B-openclaw-write-gates.md), [SPEC-010C](SPEC-010C-commit-after-approval.md), [SPEC-010D](SPEC-010D-push-pr-after-approval.md)

## Cel

Zdefiniować **jednoznaczny model** approval-first dla tasków na T630: stany, bramki (`gate`), typy zdarzeń, format artefaktu na dysku — tak, aby skrypty (010C/010D) i polityki OpenClaw (010B) mogły weryfikować „czy wolno commitować/pushować” bez OCP.

## Zakres

1. Katalog [`contracts/approvals/`](../contracts/approvals/):
   - [`task-states.yml`](../contracts/approvals/task-states.yml) — automaton stanów
   - [`events.yml`](../contracts/approvals/events.yml) — typy zdarzeń i pola
   - [`gates.yml`](../contracts/approvals/gates.yml) — bramki vs akcje Git/PR
   - [`task-artifact.example.json`](../contracts/approvals/task-artifact.example.json) — przykład `task.json`
   - [`README.md`](../contracts/approvals/README.md) — skrót dla implementatorów
   - [`enforcement.yml`](../contracts/approvals/enforcement.yml) — warstwy obrony (szczegóły w [010B](SPEC-010B-openclaw-write-gates.md))
2. Mapowanie na [PROJEKT.md](../PROJEKT.md) § Zasady approval-first.
3. Decyzje MVP z otwartych pytań EPIC-010 (patrz § Decyzje).
4. Aktualizacja [`contracts/README.md`](../contracts/README.md) — typ `approvals/`.

## Poza zakresem

- Implementacja skryptów `task-init`, `task-approve`, `task-status` (→ 010C/010D)
- Polityki OpenClaw YAML (→ 010B)
- UI LibreChat / przyciski Approve
- Wpis do `contracts/secrets/` (brak nowych sekretów)

## Decyzje MVP (rozstrzygnięcie pytań z EPIC-010)

| Pytanie | Decyzja 010A |
|---------|----------------|
| Gdzie żyje approval? | **Pliki na T630:** `/srv/worktrees/.tasks/<task-id>/task.json` + append-only `events.jsonl`. Opcjonalny skrót w `docs/worklog/` (link do task-id, bez duplikowania diffów). |
| Kto wykonuje push? | **Skrypt** `approval-push` (010D) po `approval_granted` z `gate: push_pr`; kontrakt wymaga wpisu w `events.jsonl` przed push. |
| `coding_agent` vs operator? | **Kontrakt agent-agnostyczny:** dowolny aktor może patchować worktree; `commit` / `push_pr` wymagają `approval_granted` niezależnie od agenta. Szczegóły polityk → 010B. |
| Szablon PR | Pole `spec_ref` + `test_summary` w `task.json`; body PR buduje skrypt 010D z szablonu w kontrakcie [`gates.yml`](../contracts/approvals/gates.yml). |

## Lokalizacja artefaktów (T630)

| Ścieżka | Zawartość |
|---------|-----------|
| `/srv/worktrees/<repo>-<task-id>/` | Git worktree ([008A](SPEC-008A-worktree-layout-scripts.md)) |
| `/srv/worktrees/.tasks/<task-id>/task.json` | Stan bieżący (jeden plik, nadpisywany atomowo) |
| `/srv/worktrees/.tasks/<task-id>/events.jsonl` | Historia zdarzeń (append-only) |
| `/srv/worktrees/.tasks/<task-id>/test.log` | Opcjonalny log testów (referencja w `task.json`) |

**Zakaz:** sekretów, tokenów, pełnych diffów w `.tasks/` (diff tylko w git + `difit`).

## Bramki (`gate`)

Trzy osobne zdarzenia `approval_granted` — zgodnie z EPIC-010:

| `gate` | Zezwala na | Wymagany stan wejściowy |
|--------|------------|-------------------------|
| `diff_review` | Przejście do `awaiting_commit_approval` (diff zaakceptowany) | `awaiting_diff_review` |
| `commit` | `git commit` w worktree | `awaiting_commit_approval` |
| `push_pr` | `git push` + utworzenie PR Forgejo | `awaiting_push_approval` |

`approval_denied` na dowolnej bramce → `rejected` (z `reason` w evencie).

## `approval_id`

Format: `apr-<task-id>-<gate>-<n>` gdzie `n` = kolejny numer (1, 2, …) per task i gate.

Przykład: `apr-010a-approval-contracts-commit-1`.

Pole obowiązkowe w evencie `approval_granted` / `approval_denied`; skrypty 010C/010D odmawiają akcji, jeśli brak pasującego `approval_id` w `events.jsonl` dla danej bramki.

## Mapowanie → PROJEKT.md

| Zasada PROJEKT | Realizacja w 010A |
|----------------|------------------|
| Deploy manual only | Poza taskiem; `gate` nie obejmuje deploy — osobne `APPROVE_DEPLOY` ([deploy contracts](../contracts/deploy/)) |
| Restart usług po approval | Poza taskiem; brak gate `restart` |
| Commit / PR / merge po approval | `commit`, `push_pr` gates; merge **brak gate** — tylko event `pr_merged` z `actor` human |
| Sekrety — agent nie czyta/zapisuje | Zakaz pól `secret*` w `events.yml`; artefakt bez tokenów |
| Zmiany `contracts/` świadomie | Ten SPEC jest kontraktem — zmiana wymaga review |

## Definition of Done

- [ ] Pliki w `contracts/approvals/` committed w `workspace`
- [ ] `contracts/README.md` wymienia `approvals/`
- [ ] Przykładowy `task-artifact.example.json` przechodzi walidację ręczną (pola wymagane)
- [ ] EPIC-010 linkuje 010A jako draft/done
- [ ] Worklog: `docs/worklog/EPIC-010/SPEC-010A-…md` (po implementacji review)

## Test plan (kontrakt)

```bash
# W workspace
test -f contracts/approvals/task-states.yml
test -f contracts/approvals/events.yml
test -f contracts/approvals/gates.yml
python3 -c "import json; json.load(open('contracts/approvals/task-artifact.example.json'))"

# Spójność: każdy gate w gates.yml ma przejście w task-states.yml
python3 <<'PY'
import yaml
from pathlib import Path
root = Path("contracts/approvals")
states = yaml.safe_load((root / "task-states.yml").read_text())
gates = yaml.safe_load((root / "gates.yml").read_text())
allowed = {g["id"] for g in gates["gates"]}
for t in states["transitions"]:
    if "required_gate" in t:
        assert t["required_gate"] in allowed, t
print("ok")
PY
```

## Następny krok

[SPEC-010B](SPEC-010B-openclaw-write-gates.md) — mapowanie `gate` → polityki / blokady narzędzi OpenClaw i git wrapper.
