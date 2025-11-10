#include <stdio.h>

void hello_world() {
    printf("Hello, World!\n");
}

int add_numbers(int a, int b) {
    int result = a + b;
    printf("The sum is: %d\n", result);
    return result;
}

int main() {
    hello_world();
    add_numbers(5, 3);
    return 0;
}
