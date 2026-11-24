# Problem SHELL07 — Obserwator katalogu z użyciem `inotify`

Skrypt w języku Bash (`monitor`) realizujący ciągłe monitorowanie wybranego katalogu w poszukiwaniu nowych lub zmodyfikowanych plików z wykorzystaniem mechanizmu `inotify` oraz narzędzia `inotifywait`.

## Cel zadania

Przećwiczenie zagadnień programowania systemowego w powłoce Bash:
* obsługi zdarzeń systemu plików za pomocą `inotifywait`,
* zarządzania procesami potomnymi działającymi w trybie ciągłym i ich czystego zamykania,
* bezpiecznego przetwarzania nazw plików zawierających spacje i znaki specjalne,
* kodowania ciągów znaków do postaci szesnastkowej oraz obliczania metadanych i sum kontrolnych plików.

---

## Użycie

Skrypt powinien nazywać się dokładnie `monitor` (bez rozszerzenia `.sh`) i posiadać uprawnienia do wykonywania (`chmod +x monitor`).

```bash
./monitor DIR COUNT
```

### Argumenty wywołania

| Argument | Opis |
| :--- | :--- |
| `DIR` | Ścieżka do obserwowanego katalogu (bez rekurencyjnego wchodzenia do podkatalogów). |
| `COUNT` | Liczba zdarzeń dotyczących plików zwykłych, po których obsłużeniu skrypt kończy pracę. |

> **Uwaga:** Na standardowe wyjście (`stdout`) powinny trafiać wyłącznie linie raportu. Wszelkie komunikaty diagnostyczne i błędy należy kierować na `stderr`.

---

## Opis działania

1. **Nasłuch zdarzeń:** Program uruchamia `inotifywait` w trybie monitorowania (`-m`) dla katalogu `DIR` (nierekurencyjnie), filtrując zdarzenia oznaczające zakończenie zapisu lub pojawienie się pliku:
   * `close_write` — plik otwarty do zapisu został zamknięty,
   * `moved_to` — plik został przeniesiony do obserwowanego katalogu.
2. **Weryfikacja pliku:** Dla każdego odebranego zdarzenia program sprawdza, czy docelowa ścieżka nadal istnieje oraz czy wskazuje na plik zwykły (`[ -f "$plik" ]`).
3. **Generowanie raportu:** Dla każdego poprawnego zdarzenia dotyczącego pliku zwykłego wypisywany jest jeden wiersz raportu na `stdout`.
4. **Zakończenie pracy:** Po wypisaniu dokładnie `COUNT` wierszy raportu program kończy pracę, dbając o zamknięcie procesu potomnego `inotifywait` bez pozostawiania osieroconych procesów w tle.

---

## Format raportu wyjściowego

Dla każdego obsłużonego zdarzenia program wypisuje dokładnie jedną linię w formacie rozdzielanym tabulatorami:

```text
HEX_NAZWY<TAB>ROZMIAR<TAB>MD5
```

| Pole | Opis |
| :--- | :--- |
| `HEX_NAZWY` | Sama nazwa pliku (bez ścieżki katalogu `DIR`) zakodowana bajt po bajcie w postaci szesnastkowej (małe litery, bez spacji i znaków nowej linii). |
| `ROZMIAR` | Rozmiar pliku w bajtach po zakończeniu zapisu (np. z użyciem `stat -c "%s"`). |
| `MD5` | Suma kontrolna zawartości pliku obliczona programem `md5sum` (sama suma, bez nazwy pliku). |

---

## Obsługa nietypowych nazw plików

Skrypt musi poprawnie przetwarzać nazwy plików zawierające:
* spacje,
* apostrofy (`'`) i cudzysłowy (`"`),
* średniki (`;`), nawiasy (`(`, `)`) oraz gwiazdki (`*`).

*(Na potrzeby zadania przyjmuje się, że nazwy plików nie zawierają znaku nowej linii `\n`.)*

Wszystkie odwołania do zmiennych przechowujących nazwy lub ścieżki plików muszą być odpowiednio cytowane (`"$plik"`), aby uniknąć dzielenia słów oraz rozwijania wzorców (globbing).

---

## Przykład uruchomienia

*(Uwaga: w poniższym przykładzie z treści zadania pojawia się nazwa `./watcher`, jednak docelowy plik oddawany do oceny musi nazywać się `./monitor`.)*

1. Uruchomienie obserwatora w pierwszym terminalu:
```bash
mkdir watched
./monitor watched 3
```

2. Wygenerowanie zdarzeń w drugim terminalu:
```bash
printf 'abc' > watched/a.txt
printf 'hello' > "watched/plik ze spacjami.txt"
tmp=$(mktemp /tmp/tmpXXXXXX)
printf 'xyz' > "$tmp"
mv "$tmp" watched/final.txt
```

3. Oczekiwane wyjście na `stdout` (po wypisaniu 3 linii program kończy działanie):
```text
612e747874	3	900150983cd24fb0d6963f7d28e17f72
706c696b207a6520737061636a616d692e747874	5	5d41402abc4b2a76b9719d911017c592
66696e616c2e747874	3	d16fb36f0911f878998c136191af705e
```

Gdzie:
* `612e747874` odpowiada nazwie `a.txt`,
* `706c696b207a6520737061636a616d692e747874` odpowiada nazwie `plik ze spacjami.txt`,
* `66696e616c2e747874` odpowiada nazwie `final.txt`.

---

## Wskazówki implementacyjne

* **Uruchomienie `inotifywait`:**
  ```bash
  inotifywait -m -e close_write -e moved_to --format '%f' "$dir"
  ```
* **Kodowanie nazwy do HEX:** Można wykorzystać `xxd -p` (z usunięciem ewentualnego zawijania wierszy, np. `xxd -p -c 0` lub `tr -d '\n'`) albo `od -An -tx1` odpowiednio sformatowane.
* **Sprzątanie procesów:** Jeśli `inotifywait` działa w potoku lub jako proces w tle, należy wykorzystać `trap` (np. na `EXIT`), aby po osiągnięciu limitu `COUNT` lub przerwaniu skryptu zakończyć proces `inotifywait` (`kill`).
* **Nazwa oddawanego pliku:** Do oceny należy przesłać wyłącznie jeden plik wykonywalny o nazwie `monitor`.