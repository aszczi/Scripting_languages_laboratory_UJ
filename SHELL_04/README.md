# Problem SHELL04 - Snapshot katalogu z wykorzystaniem hardlinków

## Opis zadania

Napisz skrypt w **Bashu** o nazwie `snapshot`, który tworzy kopię migawkową (snapshot) katalogu. Jeśli plik nie zmienił się względem poprzedniego snapshotu, program nie kopiuje go drugi raz, lecz tworzy hardlink do pliku z poprzedniego snapshotu.

Celem zadania jest poznanie działania hardlinków, numerów `inode` oraz praktyczne użycie poleceń takich jak `find`, `stat`, `cmp`, `cp` i `ln`, przy jednoczesnej bezpiecznej obsłudze nietypowych nazw plików.

## Wywołanie programu

```bash
./snapshot SRC PREV DEST
```

* `SRC` - katalog źródłowy, którego snapshot tworzymy (zakładamy, że istnieje).
* `PREV` - katalog z poprzednim snapshotem albo znak `-`, jeśli poprzedniego snapshotu nie ma.
* `DEST` - katalog, który program ma utworzyć jako nowy snapshot (nie powinien istnieć przed uruchomieniem programu).

## Zasady działania

Program przechodzi po wszystkich plikach zwykłych w katalogu `SRC` oraz jego podkatalogach i odtwarza odpowiednią strukturę katalogów w `DEST`:

1. **Brak poprzedniego snapshotu (`PREV` równe `-`):** Wszystkie pliki z `SRC` są kopiowane do `DEST` (poleceniem `cp`).
2. **Plik niezmieniony:** Jeśli odpowiadający plik istnieje w `PREV` i ma identyczną zawartość jak plik w `SRC`, program tworzy w `DEST` hardlink do pliku z `PREV` (poleceniem `ln`).
3. **Plik nowy lub zmieniony:** Jeśli odpowiadający plik nie istnieje w `PREV` albo ma inną zawartość, program kopiuje plik z `SRC` do `DEST` (poleceniem `cp`).
4. **Pliki usunięte:** Pliki istniejące w `PREV`, których nie ma już w `SRC`, nie pojawiają się w `DEST`.

*Do porównywania zawartości plików bajt po bajcie należy użyć polecenia `cmp -s plik1 plik2`.*

## Format raportu

Program wypisuje na `stdout` wyłącznie raport opisujący wykonane operacje (wszelkie błędy i komunikaty diagnostyczne należy kierować na `stderr`). Każda linia raportu rozdzielona jest znakami tabulacji (`<TAB>`) i przyjmuje jedną z trzech postaci:

```text
DIR<TAB>HEX_SCIEZKI
COPY<TAB>HEX_SCIEZKI<TAB>ROZMIAR
LINK<TAB>HEX_SCIEZKI<TAB>ROZMIAR
```

* `DIR` - utworzenie katalogu w `DEST`.
* `COPY` - skopiowanie pliku z `SRC` do `DEST`.
* `LINK` - utworzenie hardlinka w `DEST` do pliku z `PREV`.
* `HEX_SCIEZKI` - ścieżka względna względem katalogu `SRC` zakodowana bajt po bajcie w postaci szesnastkowej (małymi literami).
  * Ścieżka względna **nie powinna** zaczynać się od `./`.
  * Dla pliku bezpośrednio w `SRC` jest to sama nazwa pliku.
  * Dla pliku w podkatalogu są to nazwy podkatalogów rozdzielone znakiem `/`.
* `ROZMIAR` - rozmiar pliku w bajtach.

### Sortowanie raportu

* Raport należy posortować rosnąco według `HEX_SCIEZKI`.
* Jeśli dla tej samej ścieżki występuje zarówno linia `DIR`, jak i linia dotycząca pliku wewnątrz tego katalogu, jako pierwsza powinna pojawić się linia `DIR`.

## Przykład użycia

Załóżmy następującą strukturę katalogów przed uruchomieniem programu:

* Katalog `src`:
  * `src/a.txt`
  * `src/b.txt`
  * `src/pod/c.txt`
* Katalog `prev`:
  * `prev/b.txt` *(identyczna zawartość jak `src/b.txt`)*
  * `prev/pod/c.txt` *(inna zawartość niż `src/pod/c.txt`)*
  * `prev/stary.txt`

**Wywołanie:**

```bash
./snapshot src prev dest
```

**Wykonane operacje:**

* `src/a.txt` zostaje skopiowany do `dest/a.txt`,
* `src/b.txt` zostaje utworzony jako hardlink do `prev/b.txt`,
* `src/pod/c.txt` zostaje skopiowany do `dest/pod/c.txt`,
* `prev/stary.txt` nie trafia do `dest`.

**Przykładowy raport na `stdout`:**

```text
COPY	612e747874	5
LINK	622e747874	8
DIR	706f64
COPY	706f642f632e747874	12
```

*(W przykładzie `612e747874` to `a.txt`, `622e747874` to `b.txt`, `706f64` to `pod`, a `706f642f632e747874` to `pod/c.txt`).*

## Wymagania dotyczące nazw plików

* Program musi poprawnie obsługiwać nazwy plików zawierające spacje oraz inne nietypowe znaki (w systemach uniksowych nazwa pliku może zawierać dowolne bajty poza bajtem `NUL` oraz znakiem `/`).
* **Czego unikać:** Nie wolno używać pętli po podstawieniu polecenia (`for plik in $(find ...)`), ponieważ dzieli ona nazwy po białych znakach. Zalecane jest użycie `find -print0` i wczytywanie rekordów zakończonych bajtem `NUL` (`while IFS= read -r -d '' plik`).