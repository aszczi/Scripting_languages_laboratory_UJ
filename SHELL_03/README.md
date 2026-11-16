# Problem SHELL03 - Bezpieczne przetwarzanie nazw plików

## Opis zadania

Napisz dwa programy w **Bashu**, które tworzą listę plików. Celem zadania jest poprawne i bezpieczne przetwarzanie nazw plików oraz katalogów zawierających spacje oraz inne nietypowe znaki (tabulatory, znaki końca linii `0x0A`, średniki, apostrofy, cudzysłowy, nawiasy, gwiazdki, a także potencjalnie niebezpieczne konstrukcje powłoki, np. `$(rm -rf /home/$USER)`).

### Ważne ograniczenia i zasady ogólne

* **Zakaz używania *process substitution* (`<()`):** W środowisku testerki (kontenerze) użycie konstrukcji `<()` kończy się błędem `cat: /dev/fd/63: No such process`. Zamiast tego należy korzystać z plików tymczasowych tworzonych w folderze ze skryptem, np. za pomocą polecenia `mktemp`.
* **Rozdzielenie strumieni wyjściowych:** Oba programy powinny drukować na `stdout` wyłącznie wynikową listę plików. Wszelkie komunikaty diagnostyczne i błędy należy kierować na `stderr`.
* **Format wyjścia:** Dla każdego pliku program wypisuje jedną linię rozdzieloną tabulatorami:
  ```text
  HEX_SCIEZKI	ROZMIAR	MD5
  ```
  * `HEX_SCIEZKI` - ścieżka zakodowana bajt po bajcie w postaci szesnastkowej (małymi literami).
  * `ROZMIAR` - rozmiar pliku w bajtach.
  * `MD5` - suma kontrolna zawartości pliku obliczona programem `md5sum`.

---

## Program 3a (`proga`)

Program w pliku `proga` przyjmuje jako pierwszy argument ścieżkę do katalogu. Jego zadaniem jest znalezienie wszystkich plików zwykłych w tym katalogu oraz jego podkatalogach i wypisanie ich listy.

### Wymagania i zasady działania

* **Ścieżka względna:** `HEX_SCIEZKI` to ścieżka względna pliku względem katalogu podanego jako argument, zakodowana bajt po bajcie w formacie szesnastkowym.
  * Ścieżka względna **nie powinna** zaczynać się od `./`.
  * Jeśli plik znajduje się bezpośrednio w katalogu wejściowym, ścieżką względną jest sama nazwa pliku.
  * Jeśli plik znajduje się w podkatalogu, ścieżka względna zawiera nazwy podkatalogów rozdzielone znakiem `/`.
* **Sortowanie:** Wynik należy posortować rosnąco według `HEX_SCIEZKI`.
* **Obsługa znaków:** Program musi poprawnie obsługiwać spacje w nazwach plików (dla `proga` można założyć brak znaków nowej linii i tabulatorów w nazwach).
* **Czego unikać:** Nie należy używać pętli po podstawieniu polecenia:
  ```bash
  for plik in $(find "$katalog" -type f); do
      ...
  done
  ```
  ponieważ dzieli ona wynik po białych znakach i niszczy nazwy plików zawierające spacje.

### Przykład użycia (`proga`)

Dla katalogu `dane` zawierającego pliki:
* `dane/a.txt`
* `dane/ala ma kota.txt`
* `dane/pod/x.dat`

**Wywołanie:**
```bash
./proga dane
```

**Przykładowe wyjście:**
```text
612e747874	5	d8e8fca2dc0f896fd7cb4cb0031ba249
616c61206d61206b6f74612e747874	12	13803c753d251cc276e3c867d511d12b
706f642f782e646174	3	900150983cd24fb0d6963f7d28e17f72
```
*(W powyższym przykładzie `612e747874` to `a.txt`, `616c61206d61206b6f74612e747874` to `ala ma kota.txt`, a `706f642f782e646174` to `pod/x.dat`).*

---

## Program 3b (`progb`)

Program `progb` nie przyjmuje katalogu jako argumentu. Zamiast tego czyta ze standardowego wejścia (`stdin`) listę ścieżek do plików rozdzielonych bajtem NUL (format produkowany przez `find -print0`).

### Wymagania i zasady działania

* **Kodowanie ścieżki:** `HEX_SCIEZKI` oznacza **całą ścieżkę** otrzymaną na standardowym wejściu, zakodowaną bajt po bajcie w postaci szesnastkowej.
* **Sortowanie:** Wynik należy posortować rosnąco według `HEX_SCIEZKI`.
* **Obsługa znaków:** Program musi poprawnie działać dla nazw plików zawierających spacje, tabulatory, średniki, apostrofy, cudzysłowy, nawiasy, gwiazdki oraz znaki nowej linii.
* **Sposób czytania wejścia:** Nie wolno zakładać, że jedna nazwa pliku mieści się w jednej linii tekstu. Zalecany wzorzec wczytywania danych to:
  ```bash
  while IFS= read -r -d '' plik; do
      ...
  done
  ```
  *(Samo użycie `find -exec` nie rozwiązuje zadania, ponieważ `progb` musi czytać dane ze standardowego wejścia).*

### Przykład użycia (`progb`)

Dla tych samych plików w katalogu `dane`:

**Wywołanie:**
```bash
find dane -type f -print0 | ./progb
```

**Przykładowe wyjście:**
```text
64616e652f612e747874	5	d8e8fca2dc0f896fd7cb4cb0031ba249
64616e652f616c61206d61206b6f74612e747874	12	13803c753d251cc276e3c867d511d12b
64616e652f706f642f782e646174	3	900150983cd24fb0d6963f7d28e17f72
```
*(W programie `progb` kodowane są pełne ścieżki przekazane na wejście: `dane/a.txt`, `dane/ala ma kota.txt` oraz `dane/pod/x.dat`).*