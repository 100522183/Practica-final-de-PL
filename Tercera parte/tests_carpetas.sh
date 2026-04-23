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
  # Capturamos salida y errores juntos usando 2>&1
  SALIDA=$(./trad3 < "$f" | ./back3 | gforth 2>&1) || true
  
  # Buscamos la palabra "throw" de forma exacta y silenciosa
  if echo "$SALIDA" | grep -q "throw"; then
      rc=$(echo "$SALIDA" | grep -c "throw")
  else
      rc=0
  fi
  
  echo "$SALIDA"
  echo "rc=$rc"

  
  if [ $rc -eq 0 ]; then
    echo "Archivo $i compiló correctamente"
  else
    echo "Error de compilación en archivo $i(código $rc)"
  fi
  
  echo "---------------------------"
done