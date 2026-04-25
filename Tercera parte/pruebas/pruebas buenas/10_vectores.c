int vector[5];

main() {
    int i = 0;
    while (i < 5) {
        vector[i] = i * 10;
        i = i + 1;
    }
    i = 0;
    while (i < 5) {
        printf("%d", vector[i]);
        i = i + 1;
    }
}
//@ (main)
