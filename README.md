# Grafik przerw – strona na GitHub Pages

Strona statyczna hostowana na GitHub Pages. Wspólny grafik (widoczny dla wszystkich
z linkiem) trzyma darmowa baza Supabase. Grafik jest osobny dla każdego dnia, więc
następnego dnia zaczyna się pusty (dzień liczony wg Europe/Warsaw). Limit: 2 przerwy
na osobę, pilnowany po stronie bazy.

Pliki: `index.html` (strona), `config.js` (dane połączenia), `supabase-setup.sql`
(konfiguracja bazy), `.nojekyll`.

## Krok 1 – baza w Supabase: GOTOWE
Projekt `grafik-przerw` jest już założony, skrypt `supabase-setup.sql` wykonany,
a `config.js` uzupełniony. Nic więcej nie trzeba robić.
(Plik SQL zostawiłem w paczce na wypadek, gdybyś kiedyś chciał odtworzyć bazę od zera.)

## Krok 2 – GitHub Pages
1. Załóż publiczne repozytorium (np. `grafik-przerw`) na https://github.com.
2. **Add file → Upload files** i wgraj zawartość tego folderu (pliki mają leżeć
   bezpośrednio w repozytorium, nie w podfolderze), w tym `.nojekyll`. Zatwierdź (Commit).
3. **Settings → Pages**: Source = *Deploy from a branch*, Branch = `main`, folder `/ (root)` → Save.
4. Po ok. minucie strona jest pod adresem
   `https://TWOJA-NAZWA.github.io/grafik-przerw/` – ten link wysyłasz zespołowi.

## Uwagi
- Klucz w `config.js` jest publiczny z założenia. Tabela jest zablokowana dla
  bezpośredniego dostępu, a dane można zmieniać wyłącznie przez trzy funkcje z pliku SQL.
- Każdy z linkiem może wybierać terminy (brak logowania). Osoba jest rozpoznawana po
  identyfikatorze w przeglądarce, więc tryb prywatny lub inna przeglądarka to „nowa osoba”
  (da się wtedy obejść limit 2 przerw).
- Darmowy projekt Supabase jest usypiany po ok. tygodniu bez żadnej aktywności. Przy
  codziennym użyciu to nie wystąpi; po uśpieniu wystarczy go wznowić w panelu Supabase.
- Zmiana godzin lub długości przerwy: `START`, `END`, `STEP` w `index.html` oraz
  liczby 600 / 1200 / 15 w funkcji `claim_slot` (SQL). Limit przerw: `MAX` w `index.html`
  i `max_per_person` w SQL. Strefa czasowa: `Europe/Warsaw` w SQL.
  Po zmianie SQL uruchom go ponownie (funkcje się nadpiszą).
