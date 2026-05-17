# PROJEKT — AI-Native Workspace

## Cel workspace

`~/repos/workspace/` to wspólny punkt wejścia dla człowieka i agentów AI pracujących nad systemem multi-repo. Workspace daje jeden kontekst (ideas, backlog, specs, contracts, ADR, runbooki), podczas gdy wykonanie zmian pozostaje w osobnych repozytoriach domenowych.

## Dlaczego nie big-bang monorepo

- Repozytoria mają różne stacki (Ansible, Python ML, TypeScript/Node), różne ryzyko i różne cykle życia.
- Tylko część zmian (szacunkowo 20–50%) dotyczy więcej niż jednego repo naraz.
- Pełne scalenie historii Git i CI byłoby kosztowne i nieproporcjonalne do korzyści na tym etapie.
- `investment-research` wymaga twardej ściany prywatności — nie powinno być zmuszane do tego samego workflow co infra.

**Decyzja:** single workspace context + multi-repo execution. Repozytoria zostają osobne. Workspace trzyma wspólny kontekst, nie implementację wszystkiego w jednym drzewie Git.

## Mapa repozytoriów

| Repo | Typ | Odpowiedzialność | Ryzyko |
|------|-----|------------------|--------|
| `homeserver-core` | infra_stateful | OS, Docker, Tailscale, Caddy, monitoring, backup, storage | wysokie |
| `homeserver-services` | services_runtime | OpenClaw, LiteLLM, Paperclip, Airflow, usługi kontenerowe | wysokie |
| `life-platform` | personal_domain | Home Assistant, MQTT, Zigbee2MQTT, ESPHome | średnio-wysokie |
| `investment-research` | research_ip | ML, backtest, research, trading, IP | krytyczne |
| `openclaw-control-plane` | governance_policy_memory | policy, agents, memory, registry, governance | wysokie |

Lokalne checkouty są podpięte symlinkami w katalogu workspace (bez zmiany remote Git).

## Zasady spec-first

1. Luźne analizy i rozpisane pomysły trafiają najpierw do `docs/ideas/`.
2. Do `BACKLOG.md` trafiają tylko pomysły gotowe do priorytetyzacji.
3. Każda sensowna zmiana zaczyna się od SPEC (lub od child SPEC w ramach EPIC).
4. Bez zaakceptowanego SPEC nie implementujemy „na oko”.
5. Jeden agent realizuje **jeden SPEC** naraz.
6. Zmiana obejmująca wiele repo: najpierw **EPIC**, potem osobne **child SPEC** per repo/faza.

## Zasady test-first

1. Każdy SPEC ma **test plan** przed implementacją.
2. Definition of Done wymaga przejścia testów z planu (lub jawnego uzasadnienia wyjątku).
3. Diagnostyka powtarzalna trafia do `scripts/checks/`, nie zostaje tylko w historii czatu.

## Zasady approval-first

1. **Deploy** — manual only, wyłącznie po explicit approval.
2. **Restart usług** — wyłącznie po approval.
3. **Commit / PR / merge** — wyłącznie po approval użytkownika.
4. **Sekrety** — agent nie czyta, nie zapisuje, nie wypisuje wartości.
5. Zmiany w `contracts/` wymagają świadomej oceny wpływu na repo domenowe.

## Architektura pracy

```text
IDEA → BACKLOG → EPIC → SPEC → PROMPT → PATCH → TEST → REVIEW → ADR / RUNBOOK
```

| Artefakt | Rola |
|----------|------|
| `docs/ideas/` | Inkubator analiz, hipotez i rozpisanych pomysłów przed priorytetyzacją |
| `BACKLOG.md` | Priorytetyzacja idei |
| `specs/epics/` | Koordynacja multi-repo |
| `specs/` | Konkretna zmiana do wykonania |
| `contracts/` | Techniczne umowy między repo |
| `docs/adr/` | Dlaczego podjęliśmy decyzję architektoniczną |
| `docs/runbooks/` | Jak coś wykonać operacyjnie |
| `AGENTS.md` | Reguły pracy agenta |

## Fazy wdrożenia (skrót)

- **Faza 1 (done):** standard pracy — workspace, specs, contracts MVP, templates.
- **Deploy orchestration (done):** `deploy/` w workspace (EPIC-002).
- **Runtime path G2:** kanon `/opt/homeserver-services` (EPIC-005 done, 2026-05-17).
- **Następnie:** Forgejo MVP, OpenClaw `/v1`, worktree + `difit`, bot Forgejo, approval-first PR flow, selektywny GitHub mirror — każdy etap osobno, z approval.

## Dokumenty nadrzędne

- [`README.md`](README.md) — mapa workspace
- [`AGENTS.md`](AGENTS.md) — reguły dla agentów
- [`docs/ideas/`](docs/ideas/) — analizy i pomysły przed backlogiem (m.in. plany AI-Native i OpenClaw/Forgejo)
- [`BACKLOG.md`](BACKLOG.md) — kolejka pracy

`PLAN.md` w tym katalogu to starszy dokument eksploracyjny (meta-repo/submodules). Źródłem prawdy operacyjnego jest ten plik oraz `AGENTS.md`.
