#include <stdio.h>

int f() { 
    return f(); 
}
main() {
    f();
}
//@ (main)