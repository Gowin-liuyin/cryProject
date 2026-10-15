#include "mlkem.h"

#include <stdio.h>
#include <string.h>

int main(void)
{
    if (strcmp(mlkem_implementation_name(), "historical") != 0) {
        fputs("unexpected implementation label\n", stderr);
        return 1;
    }
    if (mlkem_self_test() != 0) {
        fputs("historical liboqs roundtrip failed\n", stderr);
        return 1;
    }
    puts("historical: system-random keygen/encaps/decaps roundtrip passed");
    return 0;
}
