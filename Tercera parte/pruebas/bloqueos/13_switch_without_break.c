#include <stdio.h>
main() {
    int x = 1;
    switch(x) {
        case 1: x = 2;
        case 2: x = 3;
        default: x = 0;
    }
}
//@ (main)