# Receiving code review

## Cel

Zamieniać feedback z review w bezpieczne poprawki bez ślepego przepisywania sugestii i bez deklarowania sukcesu bez weryfikacji.

## Proces

1. Sklasyfikuj każdy komentarz: blocker, important, minor albo question.
2. Dla blocker/important wskaż plik, ryzyko i oczekiwane zachowanie.
3. Jeśli komentarz jest niejasny, najpierw zadaj pytanie albo zaproponuj interpretację; nie implementuj zgadywania.
4. Popraw minimalny zakres potrzebny do zamknięcia komentarza.
5. Uruchom świeżą weryfikację związaną z poprawką.
6. Odpowiedz na review dowodem: co zmieniono, jaka komenda przeszła, co zostało poza zakresem.

## Red flags

- Akceptowanie sugestii, która łamie SPEC albo wychodzi poza zakres.
- Fix bez testu albo smoke.
- Zmiana wielu niezależnych obszarów w odpowiedzi na jeden komentarz.
- Usuwanie guardrail, żeby „uciszyć” test albo reviewer comment.
