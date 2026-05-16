# Reorganizacja repo dla Prompt-Driven Development

## Context

Projekt jest obecnie rozproszony na **5 repozytoriów** w `~/repos`:

| Repo | Stack | Rola | Rozmiar |
|------|-------|------|---------|
| `homeserver-core` | Ansible + Python | Infra stateful | 1.6M |
| `homeserver-services` | Ansible + Python + DAGs | Services + deployment | 6.6M |
| `life-platform` | Ansible + YAML | Smart home / life domain | 1.3M |
| `investment-research` | Python + Jupyter + CatBoost | ML/backtest/research | 1.5G |
| `openclaw-control-plane` | pnpm monorepo (TS/Node) + Python | Control plane + registry dla 3 repo | 1.9G |

Użytkownik chce kontynuować pracę przez **Prompt-Driven Development** (TDD + BDD/E2E) z agentem AI. Z odpowiedzi:

- **Główny ból:** kontekst dla agenta — przełączanie między repo gubi kontekst, agent nie widzi całości
- Cross-repo zmiany: **20–50%** featurów dotyka więcej niż jednego repo
- E2E: głównie unit + integration per repo (BDD nie musi obejmować całego systemu)
- Stacki: **mieszane języki**, ale podobny tooling
- Deployment: **dedykowane repo** (homeserver-services pełni tę rolę)

Cel: dać agentowi pełny kontekst całego systemu, **nie ponosząc kosztu** unifikacji CI/build dla 3 różnych stacków ani nie rozsadzając lifecycle deploymentu.

## Rekomendowane podejście: Meta-repo z git submodules

Utwórz nowy **meta-repo** `~/repos/workspace/` (lub przemianuj cały `~/repos` na workspace), który:

1. Zawiera wszystkie 5 obecnych repo jako **git submodules** — każde zachowuje własną historię, lifecycle, CI/CD, deployment.
2. Trzyma na poziomie roota **wspólne artefakty Prompt-Driven Development**:
   - `CLAUDE.md` — globalny przewodnik po systemie (architektura, granice, gdzie szukać czego)
   - `specs/` — BDD feature files (.feature) per bounded context, cross-referencujące submodule paths
   - `contracts/` — schemas API/eventów między komponentami (OpenAPI, JSON Schema, AsyncAPI) — pojedyncze źródło prawdy dla testów kontraktowych
   - `scripts/` — workspace-wide skrypty (np. `bootstrap.sh`, `run-all-tests.sh`, `sync.sh` do `git submodule update --remote`)
   - `.claude/` — wspólne settings.json, hooks, agent permissions dla całego workspace
3. Agent uruchamiany z roota workspace — widzi pełne drzewo plików, ale każdy commit trafia do właściwego submodule.

### Dlaczego ta opcja, a nie inne

- **Pełne mono-repo (jeden git):** dawałoby atomowe commity, ale wymusza unifikację CI dla Ansible + Python ML + TS/Node — duży jednorazowy koszt, a tylko 20–50% zmian jest cross-repo. Nieproporcjonalne.
- **Konsolidacja do 2–3 repo:** wymaga rzeczywistego mergowania historii git i refactoringu CI w 3 Ansible repo. Zysk pozorny — wciąż multi-repo z punktu widzenia agenta.
- **Status quo + lepszy kontekst:** nie rozwiązuje atomowości zmian cross-repo (te 20–50%) i wymaga ręcznego utrzymywania linków między repo.

Submodules to **odwracalny** krok — jeśli za 3 miesiące okaże się, że pełne mono jest lepsze, mamy gotową strukturę do `git subtree add` lub `git-filter-repo` merge.

## Struktura docelowa

```
~/repos/workspace/                   # nowy meta-repo (git init)
├── .git/
├── .gitmodules
├── CLAUDE.md                        # globalny entry-point dla agenta
├── README.md                        # mapa systemu
├── .claude/
│   ├── settings.json                # wspólne hooks/permissions
│   └── agents/                      # custom subagenty (np. "ansible-expert", "ts-tester")
├── specs/                           # BDD .feature pliki, cross-component scenariusze
│   ├── homeserver/
│   ├── life-platform/
│   └── control-plane/
├── contracts/                       # schemas (źródło prawdy między komponentami)
│   ├── openapi/
│   ├── events/
│   └── ansible-vars/
├── scripts/
│   ├── bootstrap.sh                 # klon + submodule init + bootstrap każdego komponentu
│   ├── sync.sh                      # git submodule update --remote --merge
│   └── test-all.sh                  # uruchamia testy w każdym submodule
├── homeserver-core/                 # submodule → istniejące repo
├── homeserver-services/             # submodule
├── life-platform/                   # submodule
├── investment-research/             # submodule (1.5G — opcjonalnie sparse-clone)
└── openclaw-control-plane/          # submodule
```

## Kroki implementacji

### 1. Utworzenie meta-repo (low-risk, ~15 min)
```bash
mkdir -p ~/repos/workspace && cd ~/repos/workspace
git init
git submodule add <url-or-path> homeserver-core
git submodule add <url-or-path> homeserver-services
git submodule add <url-or-path> life-platform
git submodule add <url-or-path> investment-research
git submodule add <url-or-path> openclaw-control-plane
```
> Uwaga: jeśli repo są tylko lokalne (brak `remote`), użyj `file:///Users/karolkurek/repos/<name>` jako URL submodule. Najpierw zweryfikuj `git remote -v` w każdym repo.

### 2. Napisanie globalnego `CLAUDE.md` (kluczowy artefakt PDD)

Zawartość:
- **Mapa systemu:** każdy submodule → 1-zdaniowy opis + link do jego własnego `AGENTS.md`/`README.md`
- **Granice bounded contexts** (np. „investment-research nigdy nie woła homeserver-services bezpośrednio — komunikacja przez control-plane")
- **Konwencje PDD:**
  - Gdzie żyją feature files (`specs/`)
  - Jak pisać kontrakty (`contracts/`) zanim implementacja
  - Workflow: spec → contract → test → kod → walidacja (w którym submodule)
- **Per-stack quick reference:** komendy testowe per repo (pytest, pnpm test, ansible-playbook --check)

### 3. Migracja istniejących planów/specyfikacji

OpenClaw control plane już ma sformalizowaną hierarchię Epic→Story→Task. Sprawdź czy:
- Plan zostaje w `openclaw-control-plane/` (jako control plane = naturalny właściciel orkiestracji)
- Czy linki do tasków w innych repo powinny przejść do `specs/` w meta-repo

Domyślna propozycja: plan zostaje w control-plane, ale `specs/` w meta-repo zawiera BDD .feature pliki, które plan referuje.

### 4. Skrypty workspace-level

- `scripts/bootstrap.sh` — `git submodule update --init --recursive` + per-repo bootstrap (pnpm install, uv sync, ansible-galaxy install)
- `scripts/sync.sh` — `git submodule update --remote --merge` (pull latest z każdego)
- `scripts/test-all.sh` — iteruje po submodules, uruchamia `test-all.sh` w każdym (jeśli istnieje)

### 5. Konfiguracja `.claude/` na poziomie workspace

- `settings.json`: permissions allowing read/write across all submodules
- Hooks: np. PostToolUse hook ostrzegający, jeśli zmiana dotyka >1 submodule (atomowość commitów wymaga osobnych commitów per submodule)
- `agents/`: opcjonalnie subagent „workspace-coordinator" do zmian cross-repo

## Krytyczne pliki do utworzenia / zmiany

| Plik | Akcja | Cel |
|------|-------|-----|
| `~/repos/workspace/CLAUDE.md` | **nowy** | Entry-point agenta — mapa systemu, konwencje PDD |
| `~/repos/workspace/.gitmodules` | **nowy** (auto przez `git submodule add`) | Definicja submodules |
| `~/repos/workspace/.claude/settings.json` | **nowy** | Wspólne permissions/hooks |
| `~/repos/workspace/specs/` | **nowy katalog** | BDD .feature files, cross-component |
| `~/repos/workspace/contracts/` | **nowy katalog** | Schemas API/eventów (źródło prawdy) |
| `~/repos/workspace/scripts/{bootstrap,sync,test-all}.sh` | **nowe** | Workspace tooling |
| `openclaw-control-plane/AGENTS.md` | sprawdzić, uzupełnić linki do `../specs/control-plane/` | Spójność z workspace |
| Pozostałe submodules: `AGENTS.md` / `README.md` | sprawdzić, dopisać sekcję "Workspace context" | Dwukierunkowe linki |

## Weryfikacja (end-to-end)

1. **Test struktury:**
   ```bash
   cd ~/repos/workspace
   git submodule status   # każdy submodule pokazany z hash-em
   ls -la specs/ contracts/ scripts/ .claude/
   ```

2. **Test agenta z nowym kontekstem:**
   - Uruchom Claude Code z `~/repos/workspace/`
   - Sprawdź czy przy zapytaniu „opisz architekturę systemu" agent odwołuje się do plików z wielu submodules jednocześnie
   - Spróbuj zadania cross-repo (np. „dodaj nowe pole do contractu X i zaktualizuj konsumenta w investment-research") — zweryfikuj, że agent edytuje pliki w 2 submodules w jednej sesji

3. **Test workflow PDD:**
   - Napisz przykładowy `.feature` w `specs/control-plane/example.feature`
   - Poproś agenta o wygenerowanie step-definitions i implementacji
   - Zweryfikuj, że agent rozumie, w którym submodule kod ma trafić

4. **Test izolacji deploymentu:**
   - Wejdź do `homeserver-services/`, uruchom `ansible-playbook --check` — powinno działać niezależnie, bez kontekstu z meta-repo
   - To krytyczne: meta-repo **nie może** zaburzyć lifecycle deploymentu

5. **Test odwracalności:**
   - `git submodule deinit <name>` powinno zwalniać submodule bez uszkodzenia oryginalnego repo
   - Każdy submodule można dalej klonować osobno, niezależnie od meta-repo

## Co świadomie pomijamy

- **Migracja historii git do jednego repo** — niepotrzebna, submodules zachowują historię osobno
- **Unifikacja CI** — każdy submodule trzyma własny pipeline, brak forsowania monorepo build systemu
- **Sparse-clone dla 1.5G investment-research** — można dodać później (`git config submodule.investment-research.shallow true`), jeśli rozmiar zacznie przeszkadzać
- **Workspace-wide test runner ponad `scripts/test-all.sh`** — żadnego nx/turborepo, prosty bash wystarczy dla 5 submodules

## Kiedy ten plan przestaje wystarczać

Wróć do tego pliku i rozważ pełne mono-repo, jeśli:
- Cross-repo zmiany przekroczą ~60% (atomowe commity zaczną być prawdziwym bólem)
- BDD scenariusze zaczną realnie obejmować pełne E2E przez 3+ komponenty (potrzeba spójnej wersji wszystkich naraz)
- CI/CD zaczniecie unifikować mimo wszystko (np. wspólny linter / formatter)
