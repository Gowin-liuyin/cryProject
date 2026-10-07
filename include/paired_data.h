#ifndef BASELINE_PAIRED_DATA_H
#define BASELINE_PAIRED_DATA_H

#include "timing_statistics.h"

#define PAIRED_TEXT_CAPACITY 512u
#define PAIRED_MAXIMUM_CALLS 60000u
#define PAIRED_COHORT_HEADER                                                                       \
    "block_id,first_method,baseline_csv,baseline_meta,candidate_csv,candidate_meta,baseline_csv_"  \
    "digest,baseline_meta_digest,baseline_cost_digest,candidate_csv_digest,candidate_meta_digest," \
    "candidate_cost_digest,baseline_parent_wall_ns,candidate_parent_wall_ns\n"

struct paired_text_field {
    const char *name;
    char *value;
    size_t capacity;
    int found;
};

struct batch_record {
    uint64_t first_input_index;
    uint64_t call_count;
    uint64_t category_counts[3];
    uint64_t elapsed_nanoseconds;
};

struct measurement_cost {
    uint64_t child_wall_nanoseconds;
    uint64_t child_start_nanoseconds;
    uint64_t child_finish_nanoseconds;
    uint64_t warmup_calls;
};

struct paired_run {
    char run_id[65];
    char method[16];
    char ordered_input_digest[65];
    char executable_digest[65];
    char source_commit[41];
    char compiler_flags[PAIRED_TEXT_CAPACITY];
    char compile_options[PAIRED_TEXT_CAPACITY];
    char architecture[32];
    char operating_system[128];
    char sanitizers[8];
    uint64_t test_seed;
    uint64_t call_count;
    uint64_t batch_size;
    uint64_t total_nanoseconds;
    uint64_t child_wall_nanoseconds;
    uint64_t child_start_nanoseconds;
    uint64_t child_finish_nanoseconds;
    uint64_t warmup_calls;
    size_t window_count;
    struct measurement_set baseline_sequence;
    struct batch_record *batch_records;
};

int read_paired_fields(const char *path, struct paired_text_field *fields, size_t field_count);
int split_paired_csv(char *line, char **fields, size_t field_count);
int paired_digest_file(const char *path, char digest[65]);
int is_paired_hex(const char *text, size_t character_count);
int is_paired_identifier(const char *text);
int paired_data_path(char *path, size_t capacity, const char *directory, const char *filename);
int load_measurement_cost(const char *csv_path,
    const char *expected_run_id,
    uint64_t expected_calls,
    uint64_t total_nanoseconds,
    struct measurement_cost *cost);
int load_paired_run(const char *csv_path, const char *metadata_path, struct paired_run *run);
int validate_paired_runs(const struct paired_run *baseline, const struct paired_run *candidate);
void release_paired_run(struct paired_run *run);

#endif
