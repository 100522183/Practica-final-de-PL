int cuadrado(int v) {
    return v * v;
}

int factorial(int n) {
    int f;
    if (n == 1) {
        f = 1;
    } else {
        f = n * factorial(n - 1);
    }
    return f;
}

main() {
    int a = 5;
    printf("%d", cuadrado(a));
    printf("%d", factorial(a));
}
//@ (main)