#include "localize_rank.h"

#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    struct rank_candidate candidates[RANK_CANDIDATE_CAPACITY];
    struct rank_result result;
    size_t count = 0u;
    FILE *detection_file;
    char line[128];
    int detected = 0;
    int load_status;
    if (argc != 3) {
        fputs("usage: localize_rank CANDIDATES_CSV DETECTION_PATH\n", stderr);
        return 1;
    }
    load_status = rank_load_candidates(argv[1], candidates, RANK_CANDIDATE_CAPACITY, &count);
    if (load_status != 0) {
        return load_status;
    }
    detection_file = fopen(argv[2], "r");
    if (detection_file == NULL || fgets(line, sizeof(line), detection_file) == NULL) {
        return 1;
    }
    (void)fclose(detection_file);
    if (strcmp(line, "end_to_end_detected=yes\n") == 0 ||
        strcmp(line, "end_to_end_detected=yes") == 0) {
        detected = 1;
    } else if (strcmp(line, "end_to_end_detected=no\n") != 0 &&
        strcmp(line, "end_to_end_detected=no") != 0) {
        return 1;
    }
    if (rank_order(candidates, count, detected, &result) != 0 || rank_write(stdout, &result) != 0) {
        return 1;
    }
    return 0;
}
