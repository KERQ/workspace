# SPEC-010B: Polityki zapisu + enforcement git (approval gates)

Parent: [EPIC-010](epics/EPIC-010-approval-pr-flow.md)
Status: draft
Repo: homeserver-services, workspace
Owner: karolkurek
Risk: medium
Zablokowany przez: [SPEC-010A](SPEC-010A-approval-state-contracts.md) *(kontrakty — draft zaakceptowany)*
Blokuje: [SPEC-010C](SPEC-010C-commit-after-approval.md), [SPEC-010D](SPEC-010D-push-pr-after-approval.md)

## Cel

Połączyć kontrakt [`contracts/approvals/`](../contracts/approvals/) z **egzekwowalnymi** barierami na T630: agent może edytować pliki w worktree, ale **commit**, **push** i **otwarcie PR** wymagają wpisu `approval_granted` w `events.jsonl` — niezależnie od tego, czy zapis robi OpenClaw, Cursor czy operator w SSH.

## Zakres

### 1. Kontrakt enforcement

- [`contracts/approvals/enforcement.yml`](../contracts/approvals/enforcement.yml) — mapowanie `gate` → mechanizm (skrypt, polityka OpenClaw, zakaz).

### 2. OpenClaw (homeserver-services)

| Element | Zmiana MVP |
|---------|------------|
| **LibreChat → `openclaw/default`** | Bez zmian ([007E](SPEC-007E-openclaw-tool-policies-contracts.md)) — orchestrator bez `group:fs` / `group:runtime` |
| **`coding_agent`** | Usunąć `ops_deploy` z allow dla workflow approval-first na T630; zostawić `group:fs`, `group:runtime`, `git_status` |
| **`orchestrator`** | Instrukcja w `docs/agents/orchestrator/AGENTS.md`: delegacja patchy do `coding_agent`; commit/push **tylko** przez skrypty operatora po approval |
| **`coding_agent`** | Instrukcja w `docs/agents/coding_agent/AGENTS.md`: praca **wyłącznie** w `/srv/worktrees/<repo>-<task-id>/`; zakaz `git commit` / `git push` w shellu — użyć `task-git-commit` / `approval-push` (010C/010D) |

Opcjonalnie (jeśli prostsze niż edycja listy allow): osobna flaga Ansible `openclaw_coding_agent_approval_gates: true` na `t630` wyłączająca `ops_deploy` w szablonie polityk.

### 3. Skrypty T630 (`roles/worktree` lub `roles/approval-workflow`)

Nowe pliki w `/opt/homeserver-services/bin/` (implementacja w 010C/010D; **interfejs** definiuje ten SPEC):

| Skrypt | Rola |
|--------|------|
| `approval-check` | `approval-check --task-id ID --gate commit\|push_pr` → exit 0 iff `approval_granted` w `events.jsonl` |
| `task-git-commit` | Commit w worktree po `--gate commit`; zapisuje `commit_recorded` |
| `approval-push` | Push + PR po `--gate push_pr`; zapisuje `push_recorded`, `pr_opened` |

Wspólna biblioteka: odczyt `task.json`, parsowanie `events.jsonl`, walidacja stanu wg [`task-states.yml`](../contracts/approvals/task-states.yml).

### 4. Warstwy obrony (defense in depth)

```text
[L1] LibreChat UI     → orchestrator (brak fs) — nie commituje
[L2] OpenClaw policy → coding_agent bez ops_deploy; instrukcje AGENTS.md
[L3] Skrypty bin     → jedyne ścieżki commit/push z walidacją approval
[L4] Forgejo bot     → nie pushuje (EPIC-009)
[L5] Merge           → tylko człowiek w UI Forgejo
```

**Świadomie poza MVP:** globalny wrapper `/usr/bin/git` (ryzyko regresji dla operatora). Ewentualnie **Later:** `GIT_WRAPPER=1` tylko w subshellu `worktree-create`.

## Poza zakresem

- `task-init`, `task-approve`, pełny runbook (→ 010C)
- Push/PR Forgejo API (→ 010D)
- Nowy agent `coding_agent_worktree` w LiteLLM (wystarczy instrukcje + polityka)
- Blokada `git` na poziomie kernel/ACL
- Zmiany w LibreChat UI (przyciski Approve)

## Mapowanie gate → enforcement

| Akcja | Gate | Mechanizm | Agent może sam? |
|-------|------|-----------|-----------------|
| Edycja plików w worktree | — | `group:fs` (coding_agent) | tak |
| `git status` / diff | — | `git_status`, difit | tak |
| `git commit` | `commit` | `task-git-commit` | **nie** |
| `git push` | `push_pr` | `approval-push` | **nie** |
| Utworzenie PR | `push_pr` | wewnątrz `approval-push` | **nie** |
| `ops_deploy` / restart | — | `APPROVE_DEPLOY` (osobna polityka) | **nie** |
| Merge PR | — | Forgejo UI, `actor: human` | **nie** |

Szczegóły: [`enforcement.yml`](../contracts/approvals/enforcement.yml).

## Zmienne Ansible (propozycja)

```yaml
# roles/approval-workflow/defaults/main.yml
approval_workflow_enabled: false   # true na t630 po 010C
approval_tasks_root: /srv/worktrees/.tasks
approval_bin_dir: "{{ worktree_bin_dir | default('/opt/homeserver-services/bin') }}"
openclaw_coding_agent_approval_gates: false  # true na t630: coding_agent bez ops_deploy
```

## Definition of Done

- [ ] `contracts/approvals/enforcement.yml` w workspace
- [ ] `coding_agent`: bez `ops_deploy` na T630 gdy `openclaw_coding_agent_approval_gates: true`
- [ ] Zaktualizowane `docs/agents/orchestrator/AGENTS.md` i `coding_agent/AGENTS.md`
- [ ] Szkielety skryptów w repo (implementacja + testy → 010C) **lub** stub `approval-check` z `exit 2` „not implemented”
- [ ] Krótki rozdział w runbooku (link z 010E) — „jak agent ma pracować w worktree”
- [ ] Smoke: `approval-check` bez approval → exit 1; z fałszywym eventem w testowym `events.jsonl` → exit 0

## Test plan

```bash
# Kontrakt
test -f contracts/approvals/enforcement.yml

# Po deploy na T630 (010C razem z 010B jeśli skrypty gotowe)
ssh t630 approval-check --task-id epic010b-smoke --gate commit
# oczekiwane: exit != 0 (brak approval)

# Polityka OpenClaw (grep na hoście po ansible)
ssh t630 'grep -A2 coding_agent ~/.openclaw/openclaw.json | head -5'  # orientacyjnie
# coding_agent nie powinien mieć ops_deploy w allow gdy approval gates są włączone
```

## Decyzje

| Temat | Decyzja |
|-------|---------|
| Czy blokować `git` globalnie? | **Nie** w MVP — tylko skrypty `task-git-commit` / `approval-push` |
| Czy `coding_agent` w LibreChat? | **Nie** — tylko orchestrator w UI; coding przez `sessions_send` |
| Gdzie żyje logika check? | Python + cienkie CLI w `/opt/homeserver-services/bin/`, źródło w `roles/approval-workflow/files/` |

## Następny krok

[SPEC-010C](SPEC-010C-commit-after-approval.md) — implementacja `task-approve`, `task-git-commit`, przejścia stanów `diff_review` / `commit`.
