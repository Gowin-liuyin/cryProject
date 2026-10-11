#ifndef BASELINE_LOCALIZE_RANK_H
#define BASELINE_LOCALIZE_RANK_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define RANK_CANDIDATE_CAPACITY 64u

struct rank_candidate {
    char stage_id[64];
    char function_id[128];
    char source_path[256];
    char source_line[16];
    char inline_extent[128];
    int64_t inclusive_difference_counts;
    int64_t exclusive_difference_counts;
    char evidence_path[256];
    char record_kind[16];
};

struct rank_result {
    struct rank_candidate ordered[RANK_CANDIDATE_CAPACITY];
    size_t ordered_count;
    size_t uncovered_count;
    size_t unknown_count;
    int detected;
};

int rank_load_candidates(const char *csv_path,
    struct rank_candidate *candidates,
    size_t capacity,
    size_t *count);
int rank_order(const struct rank_candidate *candidates,
    size_t count,
    int end_to_end_detected,
    struct rank_result *result);
int rank_write(FILE *output, const struct rank_result *result);

#endif
