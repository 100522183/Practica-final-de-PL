#!/usr/bin/env bash
bison -d trad3.y
bison -d back3.y
gcc -o trad3 trad3.tab.c
gcc -o back3 back3.tab.c