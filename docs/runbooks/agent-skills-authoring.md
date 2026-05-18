# Authoring repo-local skills

## Cel

Ujednolicić lokalne skille tak, żeby agent wiedział kiedy ich użyć, jaki proces wykonać i jak potwierdzić, że skill realnie zmienia zachowanie.

## Minimalny format `SKILL.md`

1. `# nazwa-skilla`
2. `Use when:` jedno zdanie z wyraźnym triggerem.
3. `Zakres`: co skill obejmuje i czego nie obejmuje.
4. `Dozwolone komendy` albo `Dozwolone działania`, jeśli skill dotyczy operacji.
5. `Zabronione komendy` / `Red flags`.
6. `Procedura`: krótki proces, najlepiej 4-6 kroków.
7. `Verification`: smoke/check potwierdzający wynik.

## Zasady

- Trigger ma być konkretny; unikaj „użyj zawsze”.
- Skill nie może omijać `AGENTS.md`, kontraktów approval ani polityki sekretów.
- Kroki mają wymuszać evidence-first: obserwacja, hipoteza, minimalna zmiana, weryfikacja.
- Skill powinien być krótki. Szczegóły operacyjne przenieś do runbooku i linkuj.

## Smoke dla skilla

Każdy nowy skill powinien mieć przynajmniej jeden test jakościowy:

```text
Given: zadanie pasujące do triggera
When: agent czyta skill
Then: agent wykonuje proces ze skilla i wskazuje komendę weryfikacyjną albo red flag
```

Przykład: dla `infra-debug` smoke jest poprawny dopiero, gdy agent najpierw zbiera logi/health, a nie zaczyna od restartu.
