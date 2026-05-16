# ADR — Architecture Decision Records

## Czym jest ADR

ADR zapisuje **decyzje architektoniczne**.

ADR odpowiada na pytanie: **dlaczego** podjęliśmy daną decyzję?

## Czym ADR nie jest

- **Nie** jest backlogiem → [`BACKLOG.md`](../../BACKLOG.md)
- **Nie** jest runbookiem → [`../runbooks/`](../runbooks/)
- **Nie** jest SPECam → [`../../specs/`](../../specs/)

## Kiedy pisać ADR

- Zmiana granic między repo
- Zmiana polityki bezpieczeństwa / prywatności
- Zmiana w `openclaw-control-plane` (policy) — wymagane per [`contracts/repos/repositories.yml`](../../contracts/repos/repositories.yml)
- Odrzucenie istotnej alternatywy, która może wrócić w dyskusji

## Szablon

[`ADR-000-template.md`](ADR-000-template.md)

## Statusy

`proposed` → `accepted` | `rejected` | `superseded`
