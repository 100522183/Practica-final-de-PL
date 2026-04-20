#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <número de la carpeta>"
  exit 1
fi

bison -d trad3.y
bison -d back3.y
gcc -o trad3 trad3.tab.c
gcc -o back3 back3.tab.c

shopt -s nullglob
dir=(../tests-2026/"$1"/*.c)
echo "Vamos a ver los archivos"
echo "${dir[@]}"

# Usamos !dir[@] para obtener los índices (0, 1, 2...)
for i in "${!dir[@]}"; do
  f="${dir[$i]}"
  
  echo "Procesando archivo [$i]: $f"

  # Tu lógica actual
  SALIDA=$(./trad3 < "$f" | ./back3 | gforth)
  
  echo "$SALIDA"

  if printf '%s\n' "$SALIDA" | grep -Eq '^main .* ok$'; then
    echo "Archivo $i: OK"
  else
    echo "Archivo $i: F en el chat"
  fi
  
  echo "---------------------------"
done