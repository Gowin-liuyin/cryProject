#include "mlkem.h"

#include <stdio.h>

int main(void)
{
    printf("implementation=%s\n", mlkem_implementation_name());
    return 0;
}
