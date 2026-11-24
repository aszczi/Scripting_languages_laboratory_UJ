#!/usr/bin/env bash

set -o pipefail

katalog_skryptu="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plik_licznika="$katalog_skryptu/counter.txt"
plik_blokady="$katalog_skryptu/counter.txt.lock"
numer_portu=6789

pokaz_pomoc() {
    printf 'Użycie: %s [-p PORT]\n' "${0##*/}" >&2
}

sprawdz_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

obsluz_klienta() {
    local zapytanie licznik

    IFS= read -r zapytanie || return 0
    case "$zapytanie" in
        '?')
            exec 9>"$plik_blokady" || return 1
            flock -x 9 || return 1
            if [[ ! -e "$plik_licznika" ]]; then
                printf '0\n' > "$plik_licznika" || return 1
            fi
            IFS= read -r licznik < "$plik_licznika" || licznik=0
            if [[ ! "$licznik" =~ ^-?[0-9]+$ ]]; then
                printf 'Nieprawidłowa zawartość pliku counter.txt\n' >&2
                return 1
            fi
            printf '%s\n' "$licznik"
            flock -u 9
            exec 9>&-
            ;;
        INC)
            exec 9>"$plik_blokady" || return 1
            flock -x 9 || return 1
            if [[ ! -e "$plik_licznika" ]]; then
                printf '0\n' > "$plik_licznika" || return 1
            fi
            IFS= read -r licznik < "$plik_licznika" || licznik=0
            if [[ ! "$licznik" =~ ^-?[0-9]+$ ]]; then
                printf 'Nieprawidłowa zawartość pliku counter.txt\n' >&2
                return 1
            fi
            printf '%s\n' "$((licznik + 1))" > "$plik_licznika" || return 1
            flock -u 9
            exec 9>&-
            ;;
        *)
            printf 'Nieznane zapytanie: %s\n' "$zapytanie" >&2
            return 1
            ;;
    esac
}

if [[ "${1-}" == '--handle' ]]; then
    obsluz_klienta
    exit $?
fi

while getopts ':p:' opcja; do
    case "$opcja" in
        p) numer_portu="$OPTARG" ;;
        :) pokaz_pomoc; exit 2 ;;
        \?) pokaz_pomoc; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if (( $# != 0 )) || ! sprawdz_port "$numer_portu"; then
    pokaz_pomoc
    exit 2
fi

if ! command -v socat >/dev/null 2>&1; then
    printf 'Wymagane polecenie socat nie jest dostępne\n' >&2
    exit 1
fi
if ! command -v flock >/dev/null 2>&1; then
    printf 'Wymagane polecenie flock nie jest dostępne\n' >&2
    exit 1
fi

exec 9>"$plik_blokady" || exit 1
flock -x 9 || exit 1
if [[ ! -e "$plik_licznika" ]]; then
    printf '0\n' > "$plik_licznika" || exit 1
fi
flock -u 9
exec 9>&-

plik_bledu="$(mktemp)" || exit 1
proces_socat=

posprzataj() {
    if [[ -n "$proces_socat" ]]; then
        kill "$proces_socat" 2>/dev/null || true
        wait "$proces_socat" 2>/dev/null || true
    fi
    rm -f -- "$plik_bledu"
}
trap posprzataj EXIT
trap 'exit 0' TERM INT HUP

sciezka_serwera="$katalog_skryptu/${BASH_SOURCE[0]##*/}"
cytowana_sciezka=${sciezka_serwera//\'/\'\\\'\'}
polecenie_obslugi="bash '$cytowana_sciezka' --handle"
socat "TCP-LISTEN:$numer_portu,reuseaddr,fork" "SYSTEM:$polecenie_obslugi" 2>"$plik_bledu" &
proces_socat=$!

wait "$proces_socat"
kod_wyjscia=$?
proces_socat=

if (( kod_wyjscia != 0 )); then
    if grep -Eqi 'Address already in use|EADDRINUSE' "$plik_bledu"; then
        printf 'Port %s is unavailable\n' "$numer_portu" >&2
    elif [[ -s "$plik_bledu" ]]; then
        cat "$plik_bledu" >&2
    fi
fi

exit "$kod_wyjscia"
