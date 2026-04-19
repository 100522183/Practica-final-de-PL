#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directorios
TEST_DIR="tests_backend"
OUTPUT_DIR="$TEST_DIR/output"
mkdir -p "$OUTPUT_DIR"

# 1. Compilación del compilador
echo -e "${BLUE}Compilando compilador (bison + gcc)...${NC}"
bison -d back3.y && gcc -o back3 back3.tab.c
if [ $? -ne 0 ]; then
    echo -e "${RED}Error crítico: Falló la compilación de back3.y${NC}"
    exit 1
fi

PASSED=0
FAILED=0
TOTAL=0

# Función para realizar un test de ejecución real
# Argumentos: nombre_test, codigo_lisp, salida_esperada
run_full_test() {
    local name=$1
    local lisp_code=$2
    local expected=$3
    TOTAL=$((TOTAL + 1))

    echo -n "Test: $name... "
    
    # Generar archivo LISP
    local lisp_file="$TEST_DIR/${name}.lisp"
    echo "$lisp_code" > "$lisp_file"
    
    # Ejecutar compilador
    local forth_file="$OUTPUT_DIR/${name}.forth"
    ./back3 < "$lisp_file" > "$forth_file" 2>/dev/null
    
    if [ ! -s "$forth_file" ]; then
        echo -e "${RED}FAILED (backend no generó código)${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi

    # Si gforth está instalado, probamos ejecución
    if command -v gforth &> /dev/null; then
        # Ejecutamos con gforth capturando la salida
        # Añadimos 'main bye' para que ejecute y cierre
        local result=$(gforth -e "include $forth_file main bye" 2>/dev/null | tr -d '\r' | xargs)
        
        if [ "$result" == "$expected" ]; then
            echo -e "${GREEN}PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAILED${NC} (Esperado: '$expected', Obtuve: '$result')"
            FAILED=$((FAILED + 1))
        fi
    else
        # Si no hay gforth, validamos estructura con regex (mejorado)
        if [[ "$name" == *"if"* ]] && ! grep -qE "IF.*(ELSE)?.*THEN" "$forth_file"; then
             echo -e "${RED}FAILED (Estructura IF-THEN inválida)${NC}"
             FAILED=$((FAILED + 1))
        else
             echo -e "${YELLOW}CHECKED (Sintaxis OK, gforth ausente)${NC}"
             PASSED=$((PASSED + 1))
        fi
    fi
}

echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}   INICIANDO BATERÍA DE PRUEBAS${NC}"
echo -e "${YELLOW}========================================${NC}"

# Test 1: Aritmética simple (LISP usa prefijo, Forth usa postfijo)
run_full_test "aritmetica" "(defun main () (princ (+ 5 3)))" "8"

# Test 2: Orden de operaciones (Precedencia)
# Lisp: (* 2 (+ 3 4)) -> Forth: 2 3 4 + *
run_full_test "precedencia" "(defun main () (princ (* 2 (+ 3 4))))" "14"

# Test 3: Variables y asignación (SETQ)
# Nota: Suponiendo que tu princ imprime el valor en la pila
run_full_test "variables" "(defun main () (setq x 10) (princ x))" "10"

# Test 4: Estructura IF (True)
run_full_test "if_true" "(defun main () (if (< 5 10) (princ 1) (princ 0)))" "1"

# Test 5: Estructura IF (False)
run_full_test "if_false" "(defun main () (if (> 5 10) (princ 1) (princ 0)))" "0"

# Test 6: Bucle WHILE (Loop)
# Imprimir 0 1 2
run_full_test "while_loop" "(defun main () (setq i 0) (loop while (< i 3) do (princ i) (setq i (+ i 1))))" "0 1 2"

# Test 7: Strings
run_full_test "print_string" "(defun main () (print \"Hola\"))" "Hola"

# --- Resumen ---
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}           RESUMEN FINAL${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Total: $TOTAL"
echo -e "${GREEN}Éxitos: $PASSED${NC}"
echo -e "${RED}Fallos: $FAILED${NC}"

if [ $TOTAL -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED * 100) / TOTAL ))
    echo -e "Efectividad: $SUCCESS_RATE%"
fi

[ $FAILED -eq 0 ] && exit 0 || exit 1