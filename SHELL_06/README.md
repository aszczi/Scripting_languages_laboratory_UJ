# Problem SHELL06 — Serwer, klient i skrypt kontrolny TCP

Zestaw trzech współpracujących skryptów w języku Bash (`server.sh`, `client.sh`, `control.sh`), implementujących prosty serwer TCP przechowujący licznik, klienta testowego oraz skrypt zarządzający procesem serwera.

## Cel zadania

Przećwiczenie kluczowych zagadnień programowania systemowego w powłoce Bash:
* uruchamiania demonów/procesów w tle i śledzenia ich numerów PID (`server.pid`),
* obsługi sygnałów oraz bezpiecznego zatrzymywania procesów (`kill`),
* wielopoziomowej konfiguracji skryptów (argumenty CLI, plik konfiguracyjny `~/.config/server.conf`, wartości domyślne),
* komunikacji sieciowej przez protokół TCP (przy użyciu `socat` lub `nc`),
* ścisłego oddzielenia danych wyjściowych (`stdout`) od komunikatów diagnostycznych (`stderr`).

## Wymagane pliki

Do oddania przeznaczone są dokładnie trzy pliki wykonywalne (z nadanymi uprawnieniami `chmod +x`):
1. `server.sh`
2. `client.sh`
3. `control.sh`

---

## Komponenty systemu

### 1. Serwer TCP (`server.sh`)

Nasłuchuje połączeń TCP (np. za pomocą `socat` lub `nc`) i obsługuje sekwencyjne zapytania klientów aż do momentu zatrzymania.

* **Uruchomienie:**
  ```bash
  ./server.sh [-p PORT]
  ```
* **Domyślny port:** `6789` (możliwy do nadpisania przełącznikiem `-p`).
* **Obsługa zajętego portu:** Jeśli wybrany port jest już używany, skrypt wypisuje na `stderr` dokładnie komunikat:
  ```text
  Port XXXX is unavailable
  ```
  (gdzie `XXXX` to numer portu) i kończy działanie z niezerowym kodem wyjścia.
* **Trwałość stanu (`counter.txt`):**
  * Wartość licznika przechowywana jest w pliku `counter.txt` zlokalizowanym w **katalogu, w którym znajduje się plik `server.sh`** (niezależnie od katalogu roboczego wywołania).
  * Jeśli plik `counter.txt` istnieje przy starcie, serwer wczytuje z niego wartość początkową; w przeciwnym razie licznik startuje od `0`.
  * Każda modyfikacja licznika jest natychmiast zapisywana do `counter.txt`.

#### Protokół komunikacji
| Zapytanie klienta | Działanie serwera | Odpowiedź serwera |
| :--- | :--- | :--- |
| `?` | Odczyt aktualnej wartości licznika | Liczba całkowita zakończona `\n` |
| `INC` | Zwiększenie licznika o `1` i zapis do `counter.txt` | Brak odpowiedzi (puste wyjście) |

---

### 2. Skrypt kontrolny (`control.sh`)

Zarządza cyklem życia procesu serwera oraz jego plikiem PID (`server.pid`), przechowywanym w **katalogu, w którym znajduje się `control.sh`**.

* **Obsługiwane polecenia:**
  ```bash
  ./control.sh start [PORT]
  ./control.sh stop
  ./control.sh restart [PORT]
  ./control.sh status
  ```

| Polecenie | Opis działania | Wyjście na `stdout` |
| :--- | :--- | :--- |
| `start [PORT]` | Uruchamia `server.sh` w tle i zapisuje PID w `server.pid`. Jeśli serwer już działa, nie uruchamia drugiej instancji. | Brak |
| `stop` | Zatrzymuje działający serwer (np. przez `kill`) i usuwa plik `server.pid`. | Brak |
| `restart [PORT]` | Wykonuje operację `stop`, a następnie `start [PORT]`. | Brak |
| `status` | Weryfikuje, czy proces o PID z `server.pid` nadal działa (`kill -0`). | Tylko numer `PID` (lub nic, jeśli serwer nie działa) |

*(Jeśli plik `server.pid` istnieje, ale proces o tym numerze już nie działa, skrypt traktuje plik jako nieaktualny.)*

#### Priorytety wyboru portu w `control.sh`
1. Port podany bezpośrednio jako argument wywołania (`start PORT` lub `restart PORT`).
2. Port odczytany z pliku `~/.config/server.conf` (jeśli plik istnieje; zawiera wyłącznie sam numer portu, np. `6543`).
3. Port domyślny: `6789`.

Wybrany port przekazywany jest do serwera za pomocą flagi `-p` (np. `./server.sh -p 6543`).

---

### 3. Klient TCP (`client.sh`)

Prosty klient komunikujący się z serwerem na hoście `localhost`.

* **Uruchomienie:**
  ```bash
  ./client.sh test1
  ```
* **Konfiguracja portu:** Domyślnie używa portu `6789`, chyba że istnieje plik `~/.config/server.conf` — wówczas odczytuje numer portu z tego pliku.
* **Scenariusz `test1`:** Wysyła kolejno zapytania: `?`, `INC`, `INC`, `?`, `INC`, `?` i wypisuje na `stdout` wyłącznie otrzymane odpowiedzi (po jednej w linii).

---

## Przykładowa sesja

Zakładając brak wcześniejszego pliku `counter.txt` (początkowy stan `0`):

```bash
./control.sh start
./control.sh status
./client.sh test1
./control.sh stop
```

Oczekiwany wynik polecenia `./client.sh test1` na `stdout`:
```text
0
2
3
```

Po ponownym uruchomieniu serwera (`./control.sh start`), licznik zostanie wczytany z pliku `counter.txt` i będzie kontynuował od wartości `3`.

---

## Wskazówki techniczne

* **Ustalanie katalogu skryptu:** Aby pliki `counter.txt` oraz `server.pid` zawsze trafiały obok odpowiednich skryptów niezależnie od miejsca wywołania, warto użyć:
  ```bash
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  ```
* **Nasłuch TCP z użyciem `socat`:**
  ```bash
  socat TCP-LISTEN:"$port",reuseaddr,fork SYSTEM:"bash \"$handler_script\""
  ```
* **Czystość strumieni wyjściowych:** Testerka weryfikuje dokładną zawartość `stdout`. Wszystkie logi diagnostyczne i błędy należy kierować wyłącznie na `stderr` (`>&2`).