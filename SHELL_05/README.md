# Problem SHELL05

## Zadanie 5: raport z danych TSV i konfiguracji JSON

Napisać skrypt w Bashu, który tworzy raport na podstawie pliku tekstowego w formacie TSV oraz pliku konfiguracyjnego w formacie JSON. Celem zadania jest użycie narzędzi odpowiednich do danych: `awk` do przetwarzania danych tabelarycznych oraz `jq` do odczytywania konfiguracji zapisanej jako JSON.

Program powinien nazywać się dokładnie:

```
report
```

## Wywołanie programu

Program uruchamiamy tak:

```bash
./report WYNIKI_TSV KONFIG_JSON
```

gdzie `WYNIKI_TSV` to plik z wynikami studentów, a `KONFIG_JSON` to plik konfiguracyjny.

## Format pliku TSV

Plik `WYNIKI_TSV` zawiera dane w formacie TSV, czyli pola rozdzielone tabulatorami. Każda linia opisuje jeden wynik i ma postać:

```
GRUPA<TAB>ID_STUDENTA<TAB>PUNKTY
```

gdzie:

- `GRUPA` to nazwa grupy,
- `ID_STUDENTA` to identyfikator studenta,
- `PUNKTY` to liczba całkowita większa lub równa zero.

Plik nie zawiera wiersza nagłówkowego. Można założyć, że nazwy grup i identyfikatory studentów nie zawierają tabulatorów.

## Format pliku JSON

Plik `KONFIG_JSON` zawiera konfigurację w formacie JSON. Ma ona następującą postać:

```json
{
  "passing_score": 50,
  "groups": ["A", "B", "C"]
}
```

Pole `passing_score` oznacza minimalną liczbę punktów potrzebną do zaliczenia. Pole `groups` zawiera listę grup, które mają pojawić się w raporcie. Kolejność grup w raporcie powinna być taka sama jak kolejność w tablicy `groups` w pliku JSON.

Nie należy parsować pliku JSON ręcznie za pomocą `grep`, `sed` albo wyrażeń regularnych. Do odczytywania wartości z pliku JSON należy użyć `jq`. Testerka może używać plików JSON z innym formatowaniem, inną liczbą spacji albo inną kolejnością pól.

## Format raportu

Program powinien wypisać na stdout raport w następującym formacie:

```
Group GRUPA:
Students: AAA
Passed: BBB
Failed: CCC
Average: DDD
```

Dla każdej grupy z pliku konfiguracyjnego należy wypisać taki blok. Między blokami należy wypisać jedną pustą linię.

Znaczenie pól:

- `AAA` to liczba wyników w danej grupie,
- `BBB` to liczba wyników z punktami większymi lub równymi `passing_score`,
- `CCC` to liczba wyników z punktami mniejszymi niż `passing_score`,
- `DDD` to średnia liczba punktów w grupie, wypisana z dokładnie dwoma miejscami po przecinku.

Jeśli dana grupa nie ma żadnych wyników w pliku TSV, należy wypisać:

```
Students: 0
Passed: 0
Failed: 0
Average: 0.00
```

Na stdout ma trafić wyłącznie raport. Komunikaty diagnostyczne i błędy należy drukować na stderr.

## Przykład

Dla pliku `wyniki.tsv` (pola rozdzielone tabulatorami):

```
A	1001	80
A	1002	40
A	1003	50
B	2001	90
B	2002	10
D	4001	100
```

oraz pliku `config.json`:

```json
{
  "passing_score": 50,
  "groups": ["A", "B", "C"]
}
```

wywołanie:

```bash
./report wyniki.tsv config.json
```

powinno wypisać:

```
Group A:
Students: 3
Passed: 2
Failed: 1
Average: 56.67

Group B:
Students: 2
Passed: 1
Failed: 1
Average: 50.00

Group C:
Students: 0
Passed: 0
Failed: 0
Average: 0.00
```

Grupa `D` występuje w pliku TSV, ale nie występuje na liście `groups` w pliku JSON, więc nie pojawia się w raporcie.

## Wymagania techniczne

Do odczytania wartości `passing_score` oraz listy grup z pliku JSON należy użyć `jq`.

Do przetwarzania pliku TSV warto użyć `awk`, ustawiając separator pól na tabulator:

```bash
awk -F '\t' '...' wyniki.tsv
```

Należy uważać na różnicę między separatorem pól w danych wejściowych a formatem raportu na wyjściu. Plik TSV używa tabulatorów, ale raport jest zwykłym tekstem w dokładnie podanym formacie.

Program powinien poprawnie działać także wtedy, gdy plik JSON jest zapisany w jednej linii, na przykład:

```json
{"groups":["B","A","C"],"passing_score":60}
```

Program powinien kończyć wyjście znakiem końca linii, ale nie powinien drukować dodatkowej pustej linii po całym raporcie.

Do zrobienia jest jeden plik: `report`, dokładnie tak nazwany, bez rozszerzenia `.sh`.
