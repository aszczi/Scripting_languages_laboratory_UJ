# Problem SHELL02 - Parsowanie argumentów

## Opis zadania

Napisz dwa programy w **Bashu**, które wypiszą przekazane argumenty linii poleceń. Programy realizują niemal identyczną logikę, ale różnią się sposobem parsowania opcji oraz rodzajem obsługiwanych argumentów.

---

## Program 1 (`arg1`)

Pierwszy program należy napisać z użyciem `getopts` (wbudowanego polecenia Basha służącego do obsługi krótkich opcji). Dokumentację można sprawdzić w *Bash Reference Manual* lub poleceniem:

```bash
help getopts
```

### Składnia wywołania

```bash
./arg1 -a -d -o output -i input arg1 arg2 arg3 ... argN
```

### Wymagania i zasady działania

* **Pozycja opcji:** Jednoliterowe opcje znajdują się przed argumentami pozycyjnymi, których może być dowolna liczba.
* **Dozwolone opcje:** Jednoliterowe opcje mogą być dowolną literą poza `q`.
* **Opcje z argumentem:** W przypadku opcji `-i` oraz `-o` wymagane jest podanie argumentu będącego jednym słowem bezpośrednio po `-i` lub `-o`.
* **Obsługa opcji `-q`:** Gdy podano `-q` (niezależnie od pozostałych argumentów i opcji), program drukuje:
  ```text
  Unsupported option: -q
  ```
  i kończy wykonanie. Komunikat o `-q` ma priorytet nad komunikatem o braku argumentu dla `-i` lub `-o`.
* **Brak argumentu dla `-i` / `-o`:** Gdy po `-i` lub `-o` nie podano poprawnego argumentu, program drukuje:
  ```text
  -i -o options require a filename
  ```
  i kończy wykonanie programu.
* **Format wyjścia:**
  * Program powinien zakończyć wyjście znakiem końca linii (bez drukowania dodatkowej pustej linii na końcu).
  * Jeśli nie podano `-q`, a opcje `-i` oraz `-o` (o ile występują) mają poprawne argumenty, należy wydrukować przekazane opcje **w kolejności alfabetycznej**.
  * Następnie należy wydrukować linię `Arguments are:` i wypisać argumenty pozycyjne (`arg1`, `arg2`, ..., `argN`) w kolejności ich przekazania.
  * Jeśli nie przekazano żadnych argumentów pozycyjnych, **nie drukujemy** linii `Arguments are:`.

### Przykłady użycia (`arg1`)

#### Przykład 1
```bash
./arg1 -c -b -r
```
**Wyjście:**
```text
-b present
-c present
-r present
```

#### Przykład 2
```bash
./arg1 -c -b -r -i
```
**Wyjście:**
```text
-i -o options require a filename
```

#### Przykład 3
```bash
./arg1 -c -b -r -i ooo aaa ala ma kota
```
**Wyjście:**
```text
-b present
-c present
-i present and set to "ooo"
-r present
Arguments are:
$1=aaa
$2=ala
$3=ma
$4=kota
```

#### Przykład 4
```bash
./arg1 -c -b -r -i -o ooo aaa ala ma kota
```
**Wyjście:**
```text
-i -o options require a filename
```
*(W tym przykładzie `-i` nie ma poprawnego argumentu - napis `-o` jest kolejną opcją, a nie nazwą pliku).*

#### Przykład 5
```bash
./arg1 -c -b -r -q -i -o ooo aaa ala ma kota
```
**Wyjście:**
```text
Unsupported option: -q
```

---

## Program 2 (`arg2`)

Drugi program należy napisać z użyciem zewnętrznego narzędzia `getopt` zamiast wbudowanego `getopts`. Program obsługuje te same krótkie opcje co `arg1`, a dodatkowo pozwala wyświetlić pomoc za pomocą długiej opcji `--help`.

### Składnia wywołania

```bash
./arg2 -a -d -o output -i input --help arg1 arg2
```

### Wymagania i zasady działania

* **Obsługa `--help`:** Jeśli `--help` występuje gdziekolwiek wśród opcji podanych przed argumentami pozycyjnymi (`arg1`, ..., `argN`), program wyświetla tekst pomocy i kończy działanie.
* **Priorytety:** Opcja `--help` ma wyższy priorytet niż `-q`.
* **Pozostałe zachowanie:** Poza obsługą `--help` program `arg2` powinien zachowywać się identycznie jak `arg1` (alfabetyczna kolejność opcji, kolejność argumentów pozycyjnych, te same komunikaty błędów).

### Przykładowy tekst pomocy

```text
Usage: ./arg2 [OPTIONS] [ARGUMENTS]

Options:
  -i FILE      input file
  -o FILE      output file
  -q           unsupported option
  --help       display this help and exit
```