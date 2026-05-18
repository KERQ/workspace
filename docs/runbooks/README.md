# Runbooki — procedury operacyjne

## Czym jest runbook

Runbook opisuje **jak** coś wykonać, sprawdzić, odtworzyć albo zdiagnozować.

Runbook mówi: kroki, komendy (bez sekretów), kryteria sukcesu, eskalacja.

## Czym runbook nie jest

- **Nie** zastępuje ADR — runbook nie uzasadnia decyzji architektonicznych
- **Nie** zastępuje SPEC — runbook nie definiuje feature scope
- **Nie** przechowuje wartości sekretów

## Kiedy pisać runbook

- Deploy, restart, backup, recovery
- Diagnostyka powtarzalna (może też trafić do [`../../scripts/checks/`](../../scripts/checks/))
- Procedury multi-repo (deploy T630/G2) — workspace może trzymać skrót, szczegóły mogą zostać w repo domenowym

## Powiązanie z contracts

- Kolejność deploy: [`../../contracts/deploy/`](../../contracts/deploy/)
- Porty i exposure: [`../../contracts/services/ports.yml`](../../contracts/services/ports.yml)
- Approval-first task workflow: [`../../contracts/approvals/`](../../contracts/approvals/)

## Runbooki agentowe

- [`agent-skills-authoring.md`](agent-skills-authoring.md) — lokalny standard pisania skilli.
- [`receiving-code-review.md`](receiving-code-review.md) — jak obsługiwać feedback z review.
- [`t630-approval-pr-flow.md`](t630-approval-pr-flow.md) — worktree → approval → commit → PR → review.

Szczegółowe runbooki w repo domenowych (np. `homeserver-services/docs/runbooks/`) pozostają — workspace agreguje cross-repo widok w miarę potrzeb.
