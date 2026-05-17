# Runbook: Worktree + difit preview (T630)

**EPIC:** [EPIC-008](../specs/epics/EPIC-008-worktree-difit.md)

## Layout

| Ścieżka | Rola |
|---------|------|
| `/srv/repos/homeserver-services` | Klon SoR z Forgejo (`origin`) |
| `/srv/worktrees/<repo>-<task-id>` | Izolowany worktree na zadanie |
| `/opt/homeserver-services/bin/` | `worktree-create`, `worktree-remove`, `difit-preview`, `difit-stop` |

## Deploy

```bash
APPROVE_DEPLOY=yes ansible-playbook playbooks/t630.yml -l t630 --tags worktree,difit
```

**Mirror repo:** jeśli brak klucza SSH `t630`→Forgejo, Ansible robi `git clone --bare` z `worktree_source_fallback` (`/opt/paperclip-workspaces/homeserver-services`) i ustawia `origin` na Forgejo. Po dodaniu klucza deployowego: `git -C /srv/repos/homeserver-services fetch origin`.

Domyślna baza worktree: `main` (nie `origin/main`).

## Flow (MVP)

```bash
# 1. Worktree dla zadania
ssh t630 worktree-create homeserver-services my-task-123 origin/main

# 2. Edycje w /srv/worktrees/homeserver-services-my-task-123 (agent lub SSH)

# 3. Podgląd diffu
ssh t630 difit-preview /srv/worktrees/homeserver-services-my-task-123

# 4. Podgląd w przeglądarce (tailnet, SPEC-008C)
# Po difit-preview: http://t630.colobus-micro.ts.net:4966/  (http, nie https)
# Telefon: Tailscale ON → ten URL; bez działającego difit-preview = connection refused.
# Alternatywa: ssh -L 4966:127.0.0.1:4966 t630@192.168.1.20 → http://127.0.0.1:4966/

# 5. Po review
ssh t630 difit-stop
# commit/push tylko po approval użytkownika (poza tym runbookiem)

# 6. Sprzątanie
ssh t630 worktree-remove homeserver-services my-task-123
```

## difit — opcje

- Domyślnie pokazuje **wszystkie niezacommitowane zmiany** w worktree (`. `).
- Inne tryby: `difit staged`, `difit @ main` — uruchom ręcznie w kontenerze jeśli potrzeba.

## Uwagi

- **Tailnet (008C):** `difit-preview` włącza `tailscale serve --tcp 4966`; `difit-stop` wyłącza. Bez Caddy `/diff/` (difit bez base path).
- **Wyłączenie Serve:** `DIFIT_TAILSCALE_SERVE=0 difit-preview …`
- **Jeden preview naraz** — kontener `difit-preview` na porcie `4966`.
- **investment-research** — poza pilotem worktree.

## Smoke

```bash
ssh t630 worktree-create homeserver-services epic008-smoke origin/main
ssh t630 'echo "# smoke" >> /srv/worktrees/homeserver-services-epic008-smoke/README.md'
ssh t630 difit-preview /srv/worktrees/homeserver-services-epic008-smoke
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4966/   # przez tunel lub na T630
ssh t630 difit-stop
ssh t630 worktree-remove homeserver-services epic008-smoke
```
