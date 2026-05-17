# ADR: EPIC-005 — kanoniczna ścieżka runtime G2 `/opt/homeserver-services`

Status: accepted
Date: 2026-05-16
Decision owner: karolkurek

## Context

Repo Git nazywa się `homeserver-services`, podczas gdy na G2 przez lata używano `/opt/homeserver-ansible-repo` i osobnego `/opt/homeserver-ansible/infisical` (layout z monorepo). SPEC-004 uporządkował tylko ścieżki dev lokalne. T630 nie ma ścieżek `homeserver-ansible*`.

## Decision

1. **Kanon runtime na G2:** `/opt/homeserver-services` (bez sufiksu `-repo`).
2. Podkatalog `g2-config/` bez zmiany nazwy.
3. Migracja fazowa: zmienna Ansible → cutover hosta ze symlinkami wstecznymi → deploy Ansible na kanon → cleanup symlinków (SPEC-005A–E).
4. **T630** poza zakresem tej migracji (`life-platform-t630`, `openclaw-control-plane` osobno).

## Consequences

### Positive

- Spójność nazwy repo Git i ścieżki na hoście.
- Ansible i runbooki operacyjne wskazują jeden root.
- Rollback możliwy przez archiwum na Seagate do zakończenia 005E.

### Negative

- Okres przejściowy ze symlinkami wstecznymi (005B–005D).
- Historyczne ADR w repo domenowych zachowują stare ścieżki w treści (celowo).

### Neutral

- `inventory/group_vars/g2_servers.yml` nadal może duplikować wartości z `all.yml`.

## Alternatives considered

- `/opt/homeserver-services-repo` — odrzucone (zbędny sufiks).
- Big-bang `mv` bez symlinków — odrzucone (zbyt duże ryzyko przestoju).
- Migracja T630 pod tą samą ścieżką — odrzucone (brak katalogów na audycie).

## Follow-up

- SPEC-005E: usunąć symlinki i `.bak-*` na G2 po smoke.
- EPIC-005 zamknięty po 005E + smoke.
