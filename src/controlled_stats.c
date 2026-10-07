#define _POSIX_C_SOURCE 200809L

#include "controlled_statistics.h"
#include "paired_data.h"

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

static const char paired_header[] = "pair_index,first_total_ns,second_total_ns,call_count\n";

static int load_pairs(const char *path,
    int64_t differences_ns[CONTROLLED_MAXIMUM_PAIRS],
    size_t *pair_count,
    uint64_t *call_count)
{
    FILE *data_file = fopen(path, "r");
    char line[512];
    int operation_status = 1;
    *pair_count = 0;
    *call_count = 0;
    if (data_file == NULL) {
        return 1;
    }
    if (fgets(line, sizeof(line), data_file) == NULL || strcmp(line, paired_header) != 0) {
        goto cleanup;
    }
    while (fgets(line, sizeof(line), data_file) != NULL) {
        char *fields[4];
        uint64_t numbers[4];
        if (*pair_count >= CONTROLLED_MAXIMUM_PAIRS || split_paired_csv(line, fields, 4) != 0) {
            goto cleanup;
        }
        for (size_t field_index = 0; field_index < 4u; ++field_index) {
            if (parse_unsigned_integer(fields[field_index], &numbers[field_index]) != 0) {
                goto cleanup;
            }
        }
        if (numbers[0] != *pair_count || numbers[1] == 0 || numbers[2] == 0 ||
            numbers[1] > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            numbers[2] > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS || numbers[3] == 0 ||
            numbers[3] > 200000u || (*pair_count > 0 && numbers[3] != *call_count)) {
            goto cleanup;
        }
        differences_ns[*pair_count] = (int64_t)numbers[1] - (int64_t)numbers[2];
        *call_count = numbers[3];
        ++*pair_count;
    }
    operation_status = ferror(data_file) || *pair_count < 4u;
cleanup:
    if (fclose(data_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int analyze_pairs(const char *csv_path, const char *plan_path, const char *report_path)
{
    int64_t differences_ns[CONTROLLED_MAXIMUM_PAIRS];
    size_t pair_count;
    uint64_t call_count;
    char values[8][128];
    const char *names[8] = {"format",
        "source_kind",
        "randomization",
        "no_carryover",
        "interval_iid",
        "data_digest",
        "source_csv_digest",
        "generator_seed"};
    struct paired_text_field fields[8];
    for (size_t field_index = 0; field_index < 8u; ++field_index) {
        fields[field_index] = (struct paired_text_field){names[field_index],
            values[field_index],
            sizeof(values[field_index]),
            0};
    }
    char data_digest[65];
    char plan_digest[65];
    if (load_pairs(csv_path, differences_ns, &pair_count, &call_count) != 0 ||
        read_paired_fields(plan_path, fields, 8) != 0 ||
        strcmp(values[0], "controlled_plan_v1") != 0 ||
        (strcmp(values[1], "no_secret_synthetic") != 0 &&
            strcmp(values[1], "reference_random_labels") != 0) ||
        (strcmp(values[2], "independent_label_swaps") != 0 &&
            strcmp(values[2], "unverified") != 0) ||
        (strcmp(values[3], "verified") != 0 && strcmp(values[3], "unverified") != 0) ||
        (strcmp(values[4], "verified") != 0 && strcmp(values[4], "unverified") != 0) ||
        !is_paired_hex(values[5], 64) ||
        (strcmp(values[6], "none_synthetic") != 0 && !is_paired_hex(values[6], 64)) ||
        paired_digest_file(csv_path, data_digest) != 0 || strcmp(data_digest, values[5]) != 0 ||
        paired_digest_file(plan_path, plan_digest) != 0) {
        return 1;
    }
    uint64_t generator_seed;
    if (parse_unsigned_integer(values[7], &generator_seed) != 0) {
        return 1;
    }
    int qualified =
        strcmp(values[2], "independent_label_swaps") == 0 && strcmp(values[3], "verified") == 0;
    int has_interval = qualified && strcmp(values[4], "verified") == 0;
    struct controlled_result result;
    if (compute_controlled_result(differences_ns, pair_count, has_interval, &result) != 0) {
        return 1;
    }
    const char *result_status = !qualified || !result.has_variation ? "evidence_insufficient"
        : result.exact_p_value <= 0.01L ? "statistical_difference_detected"
                                        : "not_detected_within_budget";
    FILE *report = fopen(report_path, "wx");
    if (report == NULL) {
        return 1;
    }
    int operation_status =
        fprintf(report,
            "format=controlled_statistics_v1\nsource_kind=%s\n"
            "csv_digest=%s\nplan_digest=%s\npair_count=%zu\ncall_count=%" PRIu64
            "\nassignment_count=%" PRIu64 "\ntail_count=%" PRIu64
            "\np_value=%.15Lf\nalpha=0.01\nmean_difference_ns=%.9Lf\n"
            "randomization_qualified=%s\np_value_scope=%s\ninterval_status=%s\n"
            "secret_attribution=not_assessed\nresult_status=%s\n",
            values[1],
            data_digest,
            plan_digest,
            pair_count,
            call_count,
            result.assignment_count,
            result.tail_count,
            result.exact_p_value,
            result.mean_difference_ns / (long double)call_count,
            qualified ? "yes" : "no",
            qualified ? "conditional_randomization" : "exploratory_only",
            has_interval ? "iid_pair_percentile_bootstrap_99_percent" : "unavailable",
            result_status) < 0;
    if (has_interval &&
        fprintf(report,
            "interval_lower_ns=%.9Lf\ninterval_upper_ns=%.9Lf\nbootstrap_count=10000\n"
            "bootstrap_seed=2026100701\ninterval_rule=type7\ninterval_scope=iid_pair_model_only\n",
            result.interval_lower_ns / (long double)call_count,
            result.interval_upper_ns / (long double)call_count) < 0) {
        operation_status = 1;
    }
    if (!operation_status && fputs("report_status=complete\n", report) == EOF) {
        operation_status = 1;
    }
    if (fclose(report) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static uint64_t next_word(uint64_t *random_state)
{
    *random_state += UINT64_C(0x9e3779b97f4a7c15);
    uint64_t mixed_word = *random_state;
    mixed_word = (mixed_word ^ (mixed_word >> 30u)) * UINT64_C(0xbf58476d1ce4e5b9);
    mixed_word = (mixed_word ^ (mixed_word >> 27u)) * UINT64_C(0x94d049bb133111eb);
    return mixed_word ^ (mixed_word >> 31u);
}

static int generate_pairs(const char *scenario,
    uint64_t seed,
    const char *csv_path,
    const char *plan_path,
    const char *source_path)
{
    struct measurement_set source_set = {0};
    char source_digest[65] = "none_synthetic";
    if (source_path != NULL) {
        char metadata_path[4096];
        size_t source_length = strlen(source_path);
        if (source_length < 4u || source_length >= sizeof(metadata_path) - 1u ||
            strcmp(source_path + source_length - 4u, ".csv") != 0) {
            return 1;
        }
        (void)snprintf(metadata_path,
            sizeof(metadata_path),
            "%.*s.meta",
            (int)(source_length - 4u),
            source_path);
        struct ordinary_dataset dataset;
        if (load_ordinary_dataset(source_path, metadata_path, &dataset) != 0) {
            return 1;
        }
        source_set = dataset.measurements;
        memcpy(source_digest, dataset.csv_digest, sizeof(source_digest));
        if (source_set.record_count < 40u || strcmp(source_set.implementation, "reference") != 0) {
            free(source_set.records);
            return 1;
        }
    }
    if (source_path == NULL && strcmp(scenario, "null") != 0 && strcmp(scenario, "effect") != 0 &&
        strcmp(scenario, "ties") != 0 && strcmp(scenario, "drift") != 0 &&
        strcmp(scenario, "dependent") != 0) {
        return 1;
    }
    FILE *csv_file = fopen(csv_path, "wx");
    if (csv_file == NULL) {
        free(source_set.records);
        return 1;
    }
    int operation_status = fputs(paired_header, csv_file) == EOF;
    uint64_t random_state = seed;
    uint64_t shared_swap = next_word(&random_state) & 1u;
    for (size_t pair_index = 0; pair_index < 20u && !operation_status; ++pair_index) {
        uint64_t first_ns = source_path == NULL
            ? 100000u + (next_word(&random_state) & 1023u)
            : source_set.records[2u * pair_index].elapsed_nanoseconds;
        uint64_t second_ns = source_path == NULL
            ? 100000u + (next_word(&random_state) & 1023u)
            : source_set.records[2u * pair_index + 1u].elapsed_nanoseconds;
        if (strcmp(scenario, "ties") == 0) {
            first_ns = 100000u;
            second_ns = 100000u;
        }
        if (strcmp(scenario, "drift") == 0) {
            first_ns += 1000u * pair_index;
            second_ns += 1000u * pair_index + 500u;
        }
        if (strcmp(scenario, "dependent") == 0) {
            first_ns = 100000u + (seed & 1023u);
            second_ns = 100000u + ((seed >> 10u) & 1023u);
        }
        uint64_t pair_swap =
            strcmp(scenario, "dependent") == 0 ? shared_swap : next_word(&random_state) & 1u;
        if (pair_swap != 0) {
            uint64_t selected_ns = first_ns;
            first_ns = second_ns;
            second_ns = selected_ns;
        }
        if (strcmp(scenario, "effect") == 0) {
            first_ns += 500u;
        }
        if (fprintf(csv_file, "%zu,%" PRIu64 ",%" PRIu64 ",1\n", pair_index, first_ns, second_ns) <
            0) {
            operation_status = 1;
        }
    }
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
    free(source_set.records);
    char data_digest[65];
    if (operation_status || paired_digest_file(csv_path, data_digest) != 0) {
        return 1;
    }
    FILE *plan_file = fopen(plan_path, "wx");
    if (plan_file == NULL) {
        return 1;
    }
    operation_status =
        fprintf(plan_file,
            "format=controlled_plan_v1\nsource_kind=%s\nrandomization=%s\n"
            "no_carryover=verified\ninterval_iid=%s\ndata_digest=%s\n"
            "source_csv_digest=%s\ngenerator_seed=%" PRIu64 "\nscenario=%s\n"
            "assignment_rule=SplitMix64_low_bit_independent_pair_swap\n"
            "source_indices=%s\n",
            source_path == NULL ? "no_secret_synthetic" : "reference_random_labels",
            strcmp(scenario, "dependent") == 0 ? "unverified" : "independent_label_swaps",
            source_path == NULL && strcmp(scenario, "drift") != 0 &&
                    strcmp(scenario, "dependent") != 0
                ? "verified"
                : "unverified",
            data_digest,
            source_digest,
            seed,
            scenario,
            source_path == NULL ? "none_synthetic" : "consecutive_first_40_only") < 0;
    if (fclose(plan_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 5 && strcmp(argument_values[1], "analyze") == 0) {
        int operation_status =
            analyze_pairs(argument_values[2], argument_values[3], argument_values[4]);
        if (operation_status != 0) {
            fputs("controlled analysis failed; retain partial output\n", stderr);
        }
        return operation_status;
    }
    if (argument_count == 6 &&
        (strcmp(argument_values[1], "generate") == 0 ||
            strcmp(argument_values[1], "label-control") == 0)) {
        uint64_t seed;
        if (parse_unsigned_integer(argument_values[3], &seed) != 0) {
            return 2;
        }
        return generate_pairs(strcmp(argument_values[1], "generate") == 0 ? argument_values[2]
                                                                          : "null",
            seed,
            argument_values[4],
            argument_values[5],
            strcmp(argument_values[1], "label-control") == 0 ? argument_values[2] : NULL);
    }
    fputs(
        "Usage: controlled_stats analyze CSV PLAN NEW_REPORT\n"
        "       controlled_stats generate null|effect|ties|drift|dependent SEED NEW_CSV NEW_PLAN\n"
        "       controlled_stats label-control REFERENCE_CSV SEED NEW_CSV NEW_PLAN\n",
        stderr);
    return 2;
}
