#define INC(x) x=x+1

main() {
    int i;
    for (i = 0; i < 10; INC(i)) {
        printf("%d", i);
    }
}
//@ (main)
