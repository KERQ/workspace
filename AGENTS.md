# AGENTS — reguły pracy w workspace

Ten plik jest głównym kontekstem dla agentów uruchamianych z root workspace (`~/repos/workspace/`).

## Język

- Zawsze odpowiadaj **po polsku**, chyba że użytkownik wyraźnie poprosi o inny język.

## Przed rozpoczęciem pracy

1. Przeczytaj [`PROJEKT.md`](PROJEKT.md).
2. Sprawdź [`docs/ideas/`](docs/ideas/) — jeśli zadanie wynika z analizy jeszcze przed backlogiem.
3. Sprawdź [`BACKLOG.md`](BACKLOG.md) — czy zadanie ma priorytet i kontekst.
4. Sprawdź relevant [`specs/`](specs/) — EPIC, SPEC, templates.
5. Sprawdź relevant [`contracts/`](contracts/) — deploy, ansible, services, secrets, repos.
6. Sprawdź relevant [`docs/worklog/`](docs/worklog/) — jeśli kontynuujesz istniejący SPEC/EPIC.
7. Jeśli zmiana dotyczy operacji — sprawdź [`docs/runbooks/`](docs/runbooks/).
8. Jeśli zmiana architektoniczna — sprawdź [`docs/adr/`](docs/adr/).

## Zakazy bez explicit approval

- **Deploy** (Ansible, skrypty deploy, zmiany na hostach).
- **Restart** usług (systemd, Docker, kontenery produkcyjne).
- **Commit** do jakiegokolwiek repo.
- **PR / branch** w Git.
- **Merge** zmian.

## Sekrety

- Nie czytaj plików z sekretami (`.env`, vault, tokeny, klucze API).
- Nie zapisuj sekretów do workspace ani repo.
- Nie wypisuj wartości sekretów w odpowiedziach, logach ani patchach.
- Polityka scope: [`contracts/secrets/scopes.yml`](contracts/secrets/scopes.yml).

## Model pracy: jeden SPEC naraz

- Realizuj **jeden SPEC** w danym wątku/sesji.
- Jeśli nie ma SPEC dla zadania — **najpierw zaproponuj SPEC** (z template `specs/SPEC-000-template.md`), nie implementuj od razu.
- Mała zmiana w jednym repo → pojedynczy SPEC.
- Większy plan multi-repo → EPIC + osobne child SPEC (szablon: `specs/epics/EPIC-000-template.md`).

## Test-first w praktyce

Sekwencja w trakcie SPEC (zgodnie z `PROJEKT.md` §test-first):

1. Test plan w SPEC (komendy/scenariusze, oczekiwany wynik).
2. **Kod aplikacyjny** → najpierw napisz test, uruchom (musi być czerwony), potem minimalny patch, potem zielony.
3. **Infra** → najpierw zdefiniuj smoke/check (`--syntax-check`, `--check`, `compose config`, healthcheck, skrypt w `scripts/checks/`); potem zmiana, potem ponowny smoke.
4. **Dokumenty/kontrakty** → najpierw checklist DoR/DoD, potem treść, potem weryfikacja (lint, link check, własny check).
5. Po zakończeniu uzupełnij sekcję „Test plan (wykonany)” w SPEC.
6. Dodaj albo zaktualizuj wpis w `docs/worklog/` i podlinkuj go z SPEC/EPIC.

Bez testu/check przed zmianą — nie commitujemy.

## EPIC vs SPEC

| Sytuacja | Artefakt |
|----------|----------|
| Jedno repo, ograniczony zakres | SPEC |
| Wiele repo lub wiele faz | EPIC + child SPECs |
| EPIC | Koordynuje, nie jest miejscem na implementację wszystkiego naraz |

## Po implementacji

- Jeśli zmiana **architektoniczna** → dodaj lub zaktualizuj ADR (`docs/adr/`).
- Jeśli zmiana **operacyjna** (deploy, recovery, diagnostyka) → dodaj lub zaktualizuj runbook (`docs/runbooks/`).
- Jeśli zmiana dotyczy **`contracts/`** → oceń wpływ na repo domenowe i wskaż w SPEC/PR.
- Jeśli SPEC/EPIC został wykonany, zmienił status albo miał ważną sesję operacyjną → dodaj wpis w `docs/worklog/`.
- SPEC/EPIC ma pozostać zwięzły: linkuje do worklogu, ale nie przechowuje pełnej historii sesji.

## Granice edycji

- Domyślnie pracuj w **workspace** (specs, contracts, docs, scripts).
- **Nie edytuj** plików w repo domenowych, chyba że SPEC wyraźnie to przewiduje i użytkownik zaakceptował plan.
- Nie zmieniaj remote Git, nie migruj repozytoriów automatycznie.

## Flow (skrót)

```text
IDEA → BACKLOG → EPIC → SPEC → PROMPT → PATCH → TEST → REVIEW → WORKLOG → ADR/RUNBOOK
```

## Hosty i deploy (informacyjnie)

- Deploy jest **manual_only** — szczegóły: `contracts/deploy/`.
- Kolejność warstw na T630/G2 jest zapisana w kontraktach, nie w pamięci agenta.
- `homeserver-core` zawsze przed `life-platform` i `homeserver-services` na T630.

## Mapa repo (symlinki w workspace)

| Katalog | Rola |
|---------|------|
| `homeserver-core/` | Infra stateful |
| `homeserver-services/` | Runtime / usługi |
| `life-platform/` | Smart home |
| `investment-research/` | Research / ML (krytyczna prywatność) |
| `openclaw-control-plane/` | Governance / policy |
