#define _POSIX_C_SOURCE 200809L

#include "protocol_decision.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    struct frozen_protocol protocol;
    struct protocol_decision decision;
    struct session_effect session_effects[64];
    size_t session_count = 0u;
    uint64_t seed;
    char *end = NULL;
    if (argc != 9 || strcmp(argv[1], "--phase") != 0 || strcmp(argv[3], "--protocol") != 0 ||
        strcmp(argv[5], "--csv") != 0 || strcmp(argv[7], "--seed") != 0) {
        fputs("usage: protocol_analyze --phase PHASE --protocol PATH --csv PATH --seed SEED\n",
            stderr);
        return 1;
    }
    seed = strtoull(argv[8], &end, 10);
    if (end == argv[8] || *end != '\0') {
        return 1;
    }
    if (protocol_load(argv[4], &protocol) != 0 ||
        protocol_decide(&protocol,
            argv[6],
            argv[2],
            seed,
            &decision,
            session_effects,
            64u,
            &session_count) != 0 ||
        protocol_write_report(stdout, argv[2], &decision, session_effects, session_count) != 0) {
        return 1;
    }
    return 0;
}
