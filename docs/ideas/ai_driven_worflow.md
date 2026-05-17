# 🚀 Wizja i Standardy Projektu (AI-Driven Workflow)

Ten dokument definiuje architekturę, hierarchię informacji oraz zasady pracy w projekcie realizowanym z wykorzystaniem modeli LLM (np. Cursor, Windsurf). Główną zasadą jest minimalizacja ręcznego kodowania na rzecz zarządzania kontekstem i rygorystycznego testowania.

## 🏗️ 1. Architektura i Kontekst (Monorepo)
Projekt jest organizowany w strukturze **Monorepo**, co pozwala AI na jednoczesne modyfikowanie backendu, frontendu i infrastruktury (np. Airflow) bez gubienia kontekstu.

### Struktura katalogów:
📁 Projekt-Workspace/
 ├── 📄 PROJEKT.md          <-- Ten plik (Master Prompt / Wizja)
 ├── 📄 BACKLOG.md          <-- Globalna lista pomysłów
 ├── 📄 .cursorrules        <-- Globalne zasady dla AI doklejane do promptów
 ├── 📁 docs/               
 │    ├── 📄 MODUL_X.md     <-- Dokumentacja i DoD poszczególnych modułów
 │    └── 📁 szablony/      <-- Szablony dla powtarzalnych elementów (np. DAG-i)
 ├── 📁 src/                <-- Kod źródłowy (FE/BE/Data)
 └── 📁 tests/              <-- Testy jednostkowe i E2E

---

## 🗂️ 2. Hierarchia Informacji (Zamiast Jiry)

Zamiast Epik, Story i Zadań stosujemy płaską hierarchię opartą na plikach tekstowych:

1. **Wizja (`PROJEKT.md`):** Globalny kontekst systemu.
2. **Katalog Modułów (`MODUL_X.md`):** Zastępuje "User Story". Definiuje konkretny wycinek aplikacji. Zawiera zarys biznesowy oraz **Definition of Done (DoD)** w postaci listy testów.
3. **Scenariusz / Test:** Najmniejsza jednostka logiczna. Opisana w składni Gherkin (Given-When-Then).
4. **Prompt:** Operacyjna interakcja z AI w celu zaliczenia pojedynczego testu.

---

## 🔄 3. Przepływ Pracy: TDD & Agentic Workflow

Każda zmiana w kodzie (nowa funkcja, bugfix) musi przejść przez pętlę **Czerwone ➔ Zielone ➔ Refaktor**:

### A. Praca z nowym/istniejącym modułem:
1. **Analiza (tylko duże moduły):** AI rozbija duży pomysł na mniejsze pod-moduły (`MODUL_1.md`, `MODUL_2.md`).
2. **Definicja DoD:** Ty (lub AI) zapisujesz scenariusze E2E i testy jednostkowe w pliku `MODUL_X.md`.
3. **Generowanie Testów (Czerwone):** Podajesz AI plik modułu i każesz napisać *wyłącznie* testy. Testy muszą oblać.
4. **Implementacja Kodu (Zielone):** Podajesz AI błędy z testów i każesz zaimplementować minimum logiki potrzebnej, by przeszły na zielono.

### B. Praca z błędami (Bugfix):
Zanim AI poprawi logikę w kodzie, **musi** napisać test jednostkowy/E2E odtwarzający błąd. Dopiero gdy test zaświeci się na czerwono, AI implementuje poprawkę.

### C. Standardowe elementy (np. Airflow DAG):
Nie piszemy dokumentacji od zera. Wskazujemy AI gotowy plik np. `szablony/SZABLON_DAG.md` i zlecamy wygenerowanie testów oraz kodu dla nowego DAG-a na jego podstawie.

---

## 📥 4. Zarządzanie Backlogiem

Utrzymujemy czystość umysłu poprzez 3 poziomy zamrażania zadań:
- **Duże pomysły i wizje:** Dopisujemy jako lista punktowa do `BACKLOG.md`.
- **Usprawnienia konkretnego modułu:** Dopisujemy do sekcji `## 🧊 Na później` na samym dole odpowiedniego pliku `MODUL_X.md`.
- **Drobny dług technologiczny:** Zostawiamy w kodzie jako komentarze `// TODO:`, które AI przeskanuje i naprawi w wolnej chwili.

---

## 📝 Szablon: Jak powinien wyglądać plik MODUL_X.md

# Moduł: [Nazwa Modułu]

## 1. Kontekst i Cel
[Krótki opis tego, co moduł robi i dlaczego istnieje].

## 2. Testy Jednostkowe (Unit Tests)
- [ ] Zwraca błąd 400 przy braku wymaganych pól.
- [ ] Prawidłowo formatuje datę do ISO.

## 3. Scenariusze Użytkownika (BDD / E2E)
**Scenariusz 1: Pomyślna akcja**
- **Zakładając, że** [stan początkowy]
- **Gdy** [akcja]
- **Wtedy** [oczekiwany rezultat]

## 🧊 Na później (Backlog modułu)
- [ ] Dodać obsługę rzadkiego przypadku brzegowego.