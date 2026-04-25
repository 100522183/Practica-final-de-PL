#include <stdio.h>
#define INC(x) x=x+1
#define DEC(x) x=x-1
main() {
    int a = 5;
    INC(a);
    DEC(a);
}
//@ (main)