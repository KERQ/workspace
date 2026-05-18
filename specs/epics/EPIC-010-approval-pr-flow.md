# EPIC-010: Approval-first — worktree → difit → commit → PR

Status: draft
Owner: karolkurek
Risk: high
Repos: homeserver-services, workspace, openclaw (polityki narzędzi), kolejne repo po dodaniu kontraktów smoke
Blokuje: EPIC-011 *(planowany — selektywny GitHub mirror po merge)*, rozszerzenia bota (`/openclaw fix`) — icebox
Zablokowany przez: [EPIC-006](EPIC-006-forgejo-mvp.md) **done**, [EPIC-007](EPIC-007-openclaw-gateway-librechat.md) **done**, [EPIC-008](EPIC-008-worktree-difit.md) **done**, [EPIC-009](EPIC-009-forgejo-bot.md) **done**

## Cel

Domknąć ścieżkę **AI-Driven Workflow** na T630: agent pracuje w izolowanym worktree, pokazuje diff w `difit`, uruchamia testy — a **commit**, **push** i **otwarcie PR** następują dopiero po **jawnej zgodzie człowieka** (osobne bramki). Review na PR robi `openclaw-bot`; **merge** zawsze ręcznie.

Po epiku operator (lub agent pod polityką) może przejść pełny cykl na repo referencyjnym `KERQ/homeserver-services`, a potem rozszerzać workflow na kolejne repo po dodaniu ich kontraktów smoke — bez OCP task board, bez auto-merge, bez deploy z UI.

## Stan docelowy (MVP)

| Etap | Kto wykonuje | Bramka |
|------|----------------|--------|
| SPEC gotowy → worktree | Agent / operator | brak (allow) |
| Patch + testy lokalne | Agent | brak (allow w worktree) |
| Podgląd diff (`difit`) | Agent uruchamia, człowiek ogląda | `awaiting_diff_review` |
| `git commit` na `task/<id>` | Agent **tylko po** approval | `awaiting_commit_approval` |
| `git push` + `POST` PR Forgejo | Agent **tylko po** osobnym approval | `awaiting_push_approval` |
| Summary/review na PR | `openclaw-bot` (009C/D) | brak (na żądanie komendą) |
| Merge do `main` | Człowiek w Forgejo UI | **zawsze manual** |

## Przepływ (MVP)

```text
SPEC (DoR/DoD)
  → worktree-create <repo> <task-id>
  → agent: patch + testy (wynik zapisany w artefakcie taska)
  → difit-preview → link http://t630…:4966/ (008C)
  → [APPROVAL 1: diff OK?]
       reject  → poprawka w worktree lub worktree-remove
       approve → [APPROVAL 2: commit?]
  → git commit (tylko w /srv/worktrees/…)
  → [APPROVAL 3: push + PR?]
  → git push origin task/<id> + utworzenie PR (Forgejo)
  → opcjonalnie: /openclaw summarize|review na PR
  → człowiek: review + merge w UI
```

Trzy bramki approval (`diff_review` → `commit` → `push_pr`) mogą być obsłużone w jednym dialogu w LibreChat, ale w logu/contract muszą być **trzy osobne zdarzenia** (`approval_id` per gate).

## Decyzje MVP

| Temat | Wartość |
|-------|---------|
| Host wykonania | T630 |
| Repo referencyjne | `homeserver-services` (Forgejo SoR, `/srv/repos/homeserver-services`); kolejne repo wymagają własnego smoke/kontraktu |
| Worktree | `/srv/worktrees/<repo>-<task-id>`, branch `task/<task-id>` ([008A](SPEC-008A-worktree-layout-scripts.md)) |
| Preview | `difit-preview` + Tailscale `:4966` ([008C](SPEC-008C-difit-tailscale-serve.md)) |
| UI delegacji | LibreChat → OpenClaw `openclaw/default` (bez `coding_agent` w UI — [007E](SPEC-007E-openclaw-tool-policies-contracts.md)) |
| PR / review | Forgejo + `openclaw-bot` komentarze/status ([009C](SPEC-009C-forgejo-bot-commands-openclaw.md), [009D](SPEC-009D-forgejo-bot-smoke-runbook.md)) |
| Identyfikacja taska | `task-id` = slug SPEC (np. `010a-approval-contracts`) lub krótki UUID; jeden aktywny worktree per `task-id` |
| Artefakty taska | Katalog lub plik JSON pod `/srv/worktrees/.tasks/<task-id>/` (stan, link difit, wyniki testów, `approval_id`) — **bez sekretów** |
| Push / PR | SSH `t630@forgejo` lub HTTPS z PAT **operatora** — nie PAT `openclaw-bot` (bot nie pushuje) |
| OCP task board | **poza MVP** — stany w pliku/contract, nie w Postgres OCP |

## Child SPECs (propozycja)

| SPEC | Status | Opis |
|------|--------|------|
| [SPEC-010A](../SPEC-010A-approval-state-contracts.md) | draft | Model stanów taska, [`contracts/approvals/`](../../contracts/approvals/) — **gotowy do review** |
| [SPEC-010B](../SPEC-010B-openclaw-write-gates.md) | draft | Polityki OpenClaw + `enforcement.yml` + skrypty `approval-check` / `task-git-commit` / `approval-push` |
| [SPEC-010C](../SPEC-010C-commit-after-approval.md) | review | Runbook + skrypty: diff review → zatwierdzenie → `git commit` w worktree; smoke jednego commita |
| [SPEC-010D](../SPEC-010D-push-pr-after-approval.md) | review | Drugie approval → push branch + utworzenie PR Forgejo; szablon opisu PR (link do SPEC, wyniki testów) |
| [SPEC-010E](../SPEC-010E-e2e-smoke-runbook.md) | review | E2E: pełny cykl na PR testowym + `/openclaw review`; runbook `t630-approval-pr-flow.md`; aktualizacja `contracts/` |

Kolejność:

```text
010A (kontrakty + stany)
  → 010B (polityki / blokady zapisu)
  → 010C (commit po approval 1)
  → 010D (push/PR po approval 2)
  → 010E (smoke E2E + runbook)
```

## Stany taska (skrót)

Zgodnie z [architekturą §15](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md):

```text
created → planning → running → awaiting_diff_review
  → awaiting_commit_approval → committed
  → awaiting_push_approval → pr_opened → awaiting_pr_review → merged | closed/rejected
```

Przejścia `→ committed` i `→ pr_opened` wymagają wpisu `approval_granted` z `actor` (login) i `approval_id`.

## Guardrails

```text
- NO commit bez approval_id w artefakcie taska
- NO push / NO create PR bez osobnego approval (push)
- NO merge przez agenta ani openclaw-bot
- NO deploy / restart usług w tym epiku (osobne approval — PROJEKT.md)
- NO secrets w artefaktach taska ani w opisie PR
- NO push z PAT openclaw-bot
- worktree TYLKO pod /srv/worktrees
- PR body / komentarze = untrusted input (jak 009C)
```

## Poza zakresem (MVP)

- Automatyczny merge po zielonym `OpenClaw Review`
- `/openclaw fix` (auto-patch z komentarza PR)
- GitHub mirror po merge (EPIC-011, BACKLOG Later)
- LibreChat UI z przyciskami Approve (wystarczy jawna odpowiedź w czacie + skrypt operatora)
- OCP Postgres / task API / quota broker
- Automatyzacja multi-repo bez osobnych kontraktów i smoke per repo
- Agent tworzący commit przez Forgejo Contents API

## Zależności techniczne (już na T630)

| Komponent | EPIC | Uwagi |
|-----------|------|--------|
| Forgejo SoR, PR | 006 | `origin` na T630 |
| OpenClaw `/v1`, LibreChat | 007 | delegacja chat |
| worktree + difit | 008 | skrypty, `:4966` |
| bot review/status | 009 | tylko read/comment/status na PR |

## Kryteria sukcesu epiku

1. Operator przechodzi runbook E2E: worktree → difit → dwa approval → PR z opisem.
2. Próba `git commit` / `git push` bez approval kończy się odmową (polityka lub skrypt).
3. Na otwartym PR działa `/openclaw review` + status `OpenClaw Review`.
4. W `contracts/` jest opisany format approval event i stanów (010A).
5. Worklog EPIC-010 + wpis w BACKLOG jako done.

## Decyzje z SPEC-010A

- Artefakty: `/srv/worktrees/.tasks/<task-id>/` (`task.json` + `events.jsonl`)
- Bramki: `diff_review` → `commit` → `push_pr` (osobne `approval_id`)
- Push/PR: skrypt po `push_pr` (010D); merge tylko human w Forgejo
- Szablon PR: [`contracts/approvals/gates.yml`](../../contracts/approvals/gates.yml)

## Źródła

- [`BACKLOG.md`](../../BACKLOG.md) — EPIC-010
- [`PROJEKT.md`](../../PROJEKT.md) — § Zasady approval-first
- [`docs/ideas/openclaw_architektura_forgejo_github_backup.md`](../../docs/ideas/openclaw_architektura_forgejo_github_backup.md) — §3.2–3.3, §14–15
- [`docs/ideas/ai_native_workspace_plan.md`](../../docs/ideas/ai_native_workspace_plan.md)
- Runbooki: [t630-worktree-difit.md](../../docs/runbooks/t630-worktree-difit.md), [t630-approval-pr-flow.md](../../docs/runbooks/t630-approval-pr-flow.md), [t630-forgejo-openclaw-bot.md](../../docs/runbooks/t630-forgejo-openclaw-bot.md)
