#include "localize_rank.h"

#include <stdlib.h>
#include <string.h>

static int forbidden_header(const char *header)
{
    const char *forbidden[] = {"ground_truth", "target_name", "patch_name", "preset_target"};
    for (size_t name_index = 0; name_index < 4u; ++name_index) {
        if (strstr(header, forbidden[name_index]) != NULL) {
            return 1;
        }
    }
    return 0;
}

static int split_fields(char *line, char **fields, size_t field_count)
{
    size_t found = 0u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            if (found + 1u >= field_count) {
                return 1;
            }
            *cursor = '\0';
            found += 1u;
            fields[found] = cursor + 1;
        }
    }
    return found + 1u == field_count ? 0 : 1;
}

static int copy_field(char *destination, size_t capacity, const char *source)
{
    size_t length = strlen(source);
    if (length >= capacity) {
        return 1;
    }
    memcpy(destination, source, length + 1u);
    return 0;
}

int rank_load_candidates(const char *csv_path,
    struct rank_candidate *candidates,
    size_t capacity,
    size_t *count)
{
    static const char *header =
        "record_kind,stage_id,function_id,source_path,source_line,inline_extent,"
        "inclusive_difference_counts,exclusive_difference_counts,evidence_path";
    FILE *file = fopen(csv_path, "r");
    char line[1200];
    *count = 0u;
    if (file == NULL) {
        return 1;
    }
    if (fgets(line, sizeof(line), file) == NULL) {
        (void)fclose(file);
        return 1;
    }
    line[strcspn(line, "\r\n")] = '\0';
    if (forbidden_header(line)) {
        (void)fclose(file);
        return 2;
    }
    if (strcmp(line, header) != 0) {
        (void)fclose(file);
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *fields[9];
        char *end = NULL;
        struct rank_candidate *candidate;
        line[strcspn(line, "\r\n")] = '\0';
        if (line[0] == '\0') {
            continue;
        }
        if (*count >= capacity || split_fields(line, fields, 9u) != 0) {
            (void)fclose(file);
            return 1;
        }
        candidate = &candidates[*count];
        memset(candidate, 0, sizeof(*candidate));
        if (copy_field(candidate->record_kind, sizeof(candidate->record_kind), fields[0]) != 0 ||
            copy_field(candidate->stage_id, sizeof(candidate->stage_id), fields[1]) != 0 ||
            copy_field(candidate->function_id, sizeof(candidate->function_id), fields[2]) != 0 ||
            copy_field(candidate->source_path, sizeof(candidate->source_path), fields[3]) != 0 ||
            copy_field(candidate->source_line, sizeof(candidate->source_line), fields[4]) != 0 ||
            copy_field(candidate->inline_extent, sizeof(candidate->inline_extent), fields[5]) !=
                0 ||
            copy_field(candidate->evidence_path, sizeof(candidate->evidence_path), fields[8]) !=
                0) {
            (void)fclose(file);
            return 1;
        }
        candidate->inclusive_difference_counts = strtoll(fields[6], &end, 10);
        if (end == fields[6] || *end != '\0') {
            (void)fclose(file);
            return 1;
        }
        candidate->exclusive_difference_counts = strtoll(fields[7], &end, 10);
        if (end == fields[7] || *end != '\0') {
            (void)fclose(file);
            return 1;
        }
        *count += 1u;
    }
    (void)fclose(file);
    return 0;
}

static int worse_candidate(const struct rank_candidate *left, const struct rank_candidate *right)
{
    int64_t left_exclusive = left->exclusive_difference_counts < 0
        ? -left->exclusive_difference_counts
        : left->exclusive_difference_counts;
    int64_t right_exclusive = right->exclusive_difference_counts < 0
        ? -right->exclusive_difference_counts
        : right->exclusive_difference_counts;
    int64_t left_inclusive = left->inclusive_difference_counts < 0
        ? -left->inclusive_difference_counts
        : left->inclusive_difference_counts;
    int64_t right_inclusive = right->inclusive_difference_counts < 0
        ? -right->inclusive_difference_counts
        : right->inclusive_difference_counts;
    if (left_exclusive != right_exclusive) {
        return left_exclusive < right_exclusive;
    }
    if (left_inclusive != right_inclusive) {
        return left_inclusive < right_inclusive;
    }
    if (strcmp(left->stage_id, right->stage_id) != 0) {
        return strcmp(left->stage_id, right->stage_id) > 0;
    }
    return strcmp(left->function_id, right->function_id) > 0;
}

int rank_order(const struct rank_candidate *candidates,
    size_t count,
    int end_to_end_detected,
    struct rank_result *result)
{
    memset(result, 0, sizeof(*result));
    result->detected = end_to_end_detected;
    for (size_t candidate_index = 0; candidate_index < count; ++candidate_index) {
        if (strcmp(candidates[candidate_index].record_kind, "uncovered") == 0) {
            result->uncovered_count += 1u;
            continue;
        }
        if (strcmp(candidates[candidate_index].record_kind, "unknown") == 0) {
            result->unknown_count += 1u;
            continue;
        }
        if (strcmp(candidates[candidate_index].record_kind, "candidate") != 0) {
            continue;
        }
        if (result->ordered_count >= RANK_CANDIDATE_CAPACITY) {
            return 1;
        }
        result->ordered[result->ordered_count] = candidates[candidate_index];
        result->ordered_count += 1u;
    }
    for (size_t left = 0; left + 1u < result->ordered_count; ++left) {
        for (size_t right = left + 1u; right < result->ordered_count; ++right) {
            if (worse_candidate(&result->ordered[left], &result->ordered[right])) {
                struct rank_candidate swap = result->ordered[left];
                result->ordered[left] = result->ordered[right];
                result->ordered[right] = swap;
            }
        }
    }
    return 0;
}

static int write_rank_slot(FILE *output, const char *label, const struct rank_candidate *candidate)
{
    return fprintf(output,
               "%s_stage=%s\n%s_function=%s\n%s_source=%s:%s\n%s_inline_extent=%s\n"
               "%s_inclusive_difference=%lld\n%s_exclusive_difference=%lld\n",
               label,
               candidate->stage_id,
               label,
               candidate->function_id,
               label,
               candidate->source_path,
               candidate->source_line,
               label,
               candidate->inline_extent,
               label,
               (long long)candidate->inclusive_difference_counts,
               label,
               (long long)candidate->exclusive_difference_counts) < 0
        ? 1
        : 0;
}

int rank_write(FILE *output, const struct rank_result *result)
{
    const char *slots[] = {"top3_1", "top3_2", "top3_3"};
    if (result->detected) {
        if (fprintf(output, "single_root_cause=not_asserted\n") < 0) {
            return 1;
        }
    } else if (fprintf(output, "single_root_cause=not_forced\n") < 0) {
        return 1;
    }
    if (result->ordered_count >= 1u && write_rank_slot(output, "top1", &result->ordered[0]) != 0) {
        return 1;
    }
    if (fprintf(output,
            "top3_count=%zu\n",
            result->ordered_count < 3u ? result->ordered_count : 3u) < 0) {
        return 1;
    }
    for (size_t slot = 0; slot < 3u && slot < result->ordered_count; ++slot) {
        if (fprintf(output,
                "%s_stage=%s\n%s_function=%s\n",
                slots[slot],
                result->ordered[slot].stage_id,
                slots[slot],
                result->ordered[slot].function_id) < 0) {
            return 1;
        }
    }
    if (fprintf(output,
            "uncovered_count=%zu\nunknown_count=%zu\n",
            result->uncovered_count,
            result->unknown_count) < 0) {
        return 1;
    }
    return 0;
}
