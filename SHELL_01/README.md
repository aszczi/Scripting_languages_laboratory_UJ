# Problem SHELL01 - Tabliczka mnożenia

## Opis zadania

Napisz program w **Bashu**, który drukuje ładnie sformatowaną tabliczkę mnożenia w zakresie od $A$ do $B$.

### Wymagania funkcjonalne:
* **Struktura tabeli:**
  * Pierwszy wiersz (poza pierwszą pustą komórką) zawiera liczby od $A$ do $B$.
  * Pierwsza kolumna (poza pierwszą pustą komórką) również zawiera liczby od $A$ do $B$.
  * Pozostałe komórki zawierają iloczyn nagłówka danego wiersza oraz nagłówka danej kolumny.
  * Minimalna szerokość każdej komórki wynosi **4 znaki**.
* **Argumenty wywołania:**
  * Wartość $A$ wczytywana jest z pierwszego argumentu linii poleceń, a $B$ z drugiego.
  * W przypadku podania **tylko jednego argumentu**, przyjmujemy domyślnie $A = 1$, a podana wartość traktowana jest jako $B$.
* **Obsługa błędów:**
  * Jeśli dane wejściowe są niepoprawne (np. $B < A$, argument nie jest liczbą całkowitą, nie podano żadnego argumentu lub podano ich więcej niż dwa), skrypt **nie powinien drukować nic** na standardowe wyjście (`stdout`).

### Oczekiwany poziom techniczny:
* Odczytywanie argumentów linii poleceń (`$1`, `$2`, `$#`).
* Wyrażenia warunkowe (`if`, `[[ ... ]]`).
* Pętle (`for` / `while`).
* Arytmetyka w Bashu (`$(( ... ))`).
* Formatowanie wyjścia przy użyciu polecenia `printf`.

---

## Przykłady użycia

### Przykład 1 (dwa argumenty)
```bash
./skrypt 2 7
```
**Wyjście:**
```text
       2   3   4   5   6   7
   2   4   6   8  10  12  14
   3   6   9  12  15  18  21
   4   8  12  16  20  24  28
   5  10  15  20  25  30  35
   6  12  18  24  30  36  42
   7  14  21  28  35  42  49
```

### Przykład 2 (jeden argument - domyślne $A=1$)
```bash
./skrypt 7
```
**Wyjście:**
```text
       1   2   3   4   5   6   7
   1   1   2   3   4   5   6   7
   2   2   4   6   8  10  12  14
   3   3   6   9  12  15  18  21
   4   4   8  12  16  20  24  28
   5   5  10  15  20  25  30  35
   6   6  12  18  24  30  36  42
   7   7  14  21  28  35  42  49
```

### Przykład 3 (błędny zakres: $B < A$)
```bash
./skrypt 7 4
```
**Wyjście:**
*(brak wyjścia - puste standardowe wyjście)*

---

## Dobre praktyki w Bashu

Pisanie tego skryptu jest dobrą okazją do wdrożenia poniższych zasad czystego i bezpiecznego programowania w powłoce:

### 1. Bezpieczne ustawienia interpretera (`set`)
Warto sprawdzić dokumentację polecenia wbudowanego `set` za pomocą `help set`. Na początku skryptu zaleca się umieszczenie:
```bash
set -euo pipefail
```
* `-e` - przerywa wykonanie skryptu natychmiast po napotkaniu błędu polecenia.
* `-u` - traktuje odwołanie do nieustawionej zmiennej jako błąd.
* `-o pipefail` - sprawia, że cały potok (`|`) zwraca kod błędu, jeśli którykolwiek z jego elementów zawiedzie.

> **Uwaga:** Opcje te nie zastępują walidacji danych wejściowych - poprawność i obecność argumentów należy sprawdzić w kodzie jawnie.

### 2. Debugowanie skryptu
Namiastką debuggera w Bashu jest tryb śledzenia poleceń:
```bash
set -x  # włącza wypisywanie wykonywanych poleceń
# ... problematyczny fragment kodu ...
set +x  # wyłącza tryb debugowania
```

### 3. Shebang i prawa wykonywania
Aby skrypt uruchamiał się w odpowiednim interpreterze niezależnie od powłoki użytkownika, pierwsza linia pliku powinna zawierać *shebang*:
```bash
#!/usr/bin/env bash
```
Następnie należy nadać plikowi uprawnienia do wykonywania:
```bash
chmod +x skrypt.sh
./skrypt.sh 2 7
```

### 4. Kontrola środowiska wykonania
Środowisko użytkownika (zmienna `PATH`, funkcje powłoki, czy aliasy w sesjach interaktywnych, np. `alias ls='ls -la'`) może wpływać na działanie skryptu. Jeśli wywołanie konkretnego programu jest krytyczne, warto używać pełnych ścieżek (np. `/usr/bin/ls`) lub świadomie kontrolować zmienne środowiskowe.

### 5. Jawna walidacja danych wejściowych
Należy weryfikować liczbę przekazanych argumentów oraz ich typ (w tym zadaniu akceptujemy wyłącznie 1 lub 2 liczby całkowite/naturalne spełniające warunek $A \le B$).

### 6. Centralizacja konfiguracji
Unikaj rozrzucania zahardkodowanych ścieżek czy ustawień po całym kodzie (np. `katalog=/home/user/dane`). Wszelkie stałe konfiguracyjne powinny znajdować się na samej górze pliku, być przekazywane jako argumenty lub wczytywane z zewnętrznego pliku konfiguracyjnego.

### 7. Obsługa błędów operacji krytycznych
Samo sprawdzenie, czy katalog istnieje przed wykonaniem `cd`, nie wystarcza (skrypt może np. nie mieć uprawnień dostępu). Zawsze obsługuj niepowodzenie operacji krytycznych:
```bash
cd "$katalog" || {
    echo "Nie mogę wejść do katalogu: $katalog" >&2
    exit 1
}
```

### 8. Ochrona przed wstrzykiwaniem poleceń (Command Injection)
Dane pochodzące od użytkownika należy traktować **wyłącznie jako dane, nigdy jako kod**. Nigdy nie sklejaj argumentów w polecenia i unikaj używania `eval`, aby wpisanie tekstu w stylu `nazwa_pliku; rm -rf /` nie doprowadziło do wykonania złośliwego kodu.

### 9. Czytelność kodu i dokumentowanie funkcji
W Bashu funkcje przyjmują argumenty pozycyjne (`$1`, `$2`, ...). Dobrą praktyką jest komentowanie przeznaczenia funkcji oraz natychmiastowe przypisywanie argumentów do zmiennych lokalnych o zrozumiałych nazwach:
```bash
# Drukuje tabliczkę mnożenia dla zakresu od $1 (a) do $2 (b)
drukuj_tabelke() {
    local a="$1"
    local b="$2"

    # dalsza część funkcji operująca na $a oraz $b
}
```

### 10. Wydajność i unikanie zbędnych procesów
Skrypty powłoki są wolniejsze niż języki takie jak Python, dlatego należy unikać uruchamiania wielu zewnętrznych procesów wewnątrz pętli. Zamiast łączyć wiele narzędzi w długie potoki:
```bash
# Zamiast tego:
cat plik | sed ... | awk ... | grep ...

# Lepiej użyć jednego narzędzia:
awk '...' plik
```