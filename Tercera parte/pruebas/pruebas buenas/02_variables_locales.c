int global = 10;
main() {
    int local1;
    int local2 = 20;
    int local3[5];
    local1 = global;
    local2 = local1 + 5;
}
//@ (main)