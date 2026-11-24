#!/usr/bin/env bash

set -o pipefail

katalog_skryptu="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plik_pid="$katalog_skryptu/server.pid"
skrypt_serwera="$katalog_skryptu/server.sh"
plik_konfiguracji="${HOME:-}/.config/server.conf"

pokaz_pomoc() {
    printf 'Użycie: %s {start [PORT]|stop|restart [PORT]|status}\n' "${0##*/}" >&2
}

sprawdz_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

czy_dziala() {
    [[ -n "$1" ]] && kill -0 "$1" 2>/dev/null
}

odczytaj_pid() {
    local identyfikator_procesu
    [[ -f "$plik_pid" ]] || return 1
    IFS= read -r identyfikator_procesu < "$plik_pid" || return 1
    [[ "$identyfikator_procesu" =~ ^[0-9]+$ ]] || return 1
    printf '%s' "$identyfikator_procesu"
}

ustal_port() {
    if [[ -n "${2-}" ]]; then
        numer_portu="$2"
    elif [[ -f "$plik_konfiguracji" ]]; then
        IFS= read -r numer_portu < "$plik_konfiguracji" || numer_portu=
    else
        numer_portu=6789
    fi

    if ! sprawdz_port "$numer_portu"; then
        printf 'Nieprawidłowy numer portu\n' >&2
        return 2
    fi
}

uruchom_serwer() {
    local identyfikator_procesu

    if identyfikator_procesu="$(odczytaj_pid)" && czy_dziala "$identyfikator_procesu"; then
        return 0
    fi
    rm -f -- "$plik_pid"

    "$skrypt_serwera" -p "$numer_portu" &
    identyfikator_procesu=$!
    printf '%s\n' "$identyfikator_procesu" > "$plik_pid" || {
        kill "$identyfikator_procesu" 2>/dev/null || true
        return 1
    }

    for (( proba=0; proba<20; proba++ )); do
        if ! czy_dziala "$identyfikator_procesu"; then
            rm -f -- "$plik_pid"
            return 1
        fi
        sleep 0.1
    done
}

zatrzymaj_serwer() {
    local identyfikator_procesu proba

    if ! identyfikator_procesu="$(odczytaj_pid)"; then
        rm -f -- "$plik_pid"
        return 0
    fi

    if czy_dziala "$identyfikator_procesu"; then
        kill -TERM "$identyfikator_procesu" 2>/dev/null || return 1
        for (( proba=0; proba<50; proba++ )); do
            if ! czy_dziala "$identyfikator_procesu"; then
                break
            fi
            sleep 0.1
        done
        if czy_dziala "$identyfikator_procesu"; then
            kill -KILL "$identyfikator_procesu" 2>/dev/null || return 1
        fi
    fi

    rm -f -- "$plik_pid"
}

polecenie="${1-}"
case "$polecenie" in
    start)
        if (( $# > 2 )); then
            pokaz_pomoc
            exit 2
        fi
        ustal_port "$polecenie" "${2-}" || exit $?
        uruchom_serwer
        ;;
    stop)
        if (( $# != 1 )); then
            pokaz_pomoc
            exit 2
        fi
        zatrzymaj_serwer
        ;;
    restart)
        if (( $# > 2 )); then
            pokaz_pomoc
            exit 2
        fi
        ustal_port "$polecenie" "${2-}" || exit $?
        zatrzymaj_serwer || exit $?
        uruchom_serwer
        ;;
    status)
        if (( $# != 1 )); then
            pokaz_pomoc
            exit 2
        fi
        if identyfikator_procesu="$(odczytaj_pid)" && czy_dziala "$identyfikator_procesu"; then
            printf '%s\n' "$identyfikator_procesu"
        else
            rm -f -- "$plik_pid"
        fi
        ;;
    *)
        pokaz_pomoc
        exit 2
        ;;
esac
