#define _POSIX_C_SOURCE 200809L
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void)
{
    const char *failure_mode = getenv("PAIRED_FAILURE_MODE");
    if (failure_mode != NULL && strcmp(failure_mode, "missing") == 0) {
        return 0;
    }
    if (failure_mode != NULL && strcmp(failure_mode, "timeout") == 0) {
        for (;;) {
            (void)pause();
        }
    }
    return 17;
}
