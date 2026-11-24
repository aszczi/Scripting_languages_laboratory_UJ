#!/usr/bin/env bash

set -o pipefail

numer_portu=6789
plik_konfiguracji="${HOME:-}/.config/server.conf"

if [[ -f "$plik_konfiguracji" ]]; then
    IFS= read -r numer_portu < "$plik_konfiguracji" || numer_portu=
fi

if [[ ! "$numer_portu" =~ ^[0-9]+$ ]] || (( 10#$numer_portu < 1 || 10#$numer_portu > 65535 )); then
    printf 'Nieprawidłowy port w pliku konfiguracyjnym\n' >&2
    exit 2
fi

if [[ "${1-}" != 'test1' ]] || (( $# != 1 )); then
    printf 'Użycie: %s test1\n' "${0##*/}" >&2
    exit 2
fi

if ! command -v socat >/dev/null 2>&1; then
    printf 'Wymagane polecenie socat nie jest dostępne\n' >&2
    exit 1
fi

wyslij_zapytanie() {
    printf '%s\n' "$1" | socat - "TCP:localhost:$numer_portu"
}

wyslij_zapytanie '?' || exit $?
wyslij_zapytanie INC || exit $?
wyslij_zapytanie INC || exit $?
wyslij_zapytanie '?' || exit $?
wyslij_zapytanie INC || exit $?
wyslij_zapytanie '?'
