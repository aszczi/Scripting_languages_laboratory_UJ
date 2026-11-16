#!/usr/bin/env bash

set -euo pipefail

#Sprawdzenie ilosci pobieranych argumentow
if [[ $# = 1 ]]; then
    pierwsza_liczba=1
    druga_liczba="$1"
elif [[ $# = 2 ]]; then
    pierwsza_liczba="$1"
    druga_liczba="$2"
else
    echo "Podano niepoprawna ilosc argumentow"
    exit 0
fi

#Sprawdzenie, czy liczby sa naturalne (regex pozwalajacy tylko na cyfry)
if ! [[ "$pierwsza_liczba" =~ ^[0-9]+$ ]] || ! [[ "$druga_liczba" =~ ^[0-9]+$ ]]; then
    echo "Podane wartosci nie sa liczbami naturalnymi"
    exit 0
fi

#Sprawdzenie zakresu, poniewaz poczatek nie moze byc wiekszy od konca
if (( druga_liczba < pierwsza_liczba )); then
    #echo "Poczatek zakresu nie moze byc wiekszy od jego konca"
    exit 0
fi

#Dostosowanie szerokosci kolumn
najwieksza_liczba=$(( druga_liczba * druga_liczba ))
dlugosc=${#najwieksza_liczba}

if [[ "$dlugosc" > 4 ]]; then
    szerokosc=$(( dlugosc + 1 ))
else
    szerokosc=4
fi

#Pierwsza linijka
printf "%*s" "$szerokosc" ""
for (( kolumna = pierwsza_liczba; kolumna <= druga_liczba; kolumna++ )); do
    printf "%*d" "$szerokosc" "$kolumna"
done
printf "\n"

#Wypisanie kolejnych wierszy tabeli
for (( wiersz = pierwsza_liczba; wiersz <= druga_liczba; wiersz++ )); do
    printf "%*d" "$szerokosc" "$wiersz"

    for (( kolumna = pierwsza_liczba; kolumna <= druga_liczba; kolumna++ )); do
        wynik=$(( wiersz * kolumna ))
        printf "%*d" "$szerokosc" "$wynik"
    done

    printf "\n"
done