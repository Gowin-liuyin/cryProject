#define _POSIX_C_SOURCE 200809L

#include "v4_reduce.h"
#include "v4_stats.h"

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINE_CAPACITY 2048u
#define EFFECT_CAPACITY 64u

static int write_both(FILE *primary, FILE *secondary, const char *format, ...)
{
    va_list primary_args;
    va_list secondary_args;
    int written;
    va_start(primary_args, format);
    va_copy(secondary_args, primary_args);
    written = vfprintf(primary, format, primary_args);
    if (written >= 0) {
        written = vfprintf(secondary, format, secondary_args);
    }
    va_end(secondary_args);
    va_end(primary_args);
    return written < 0 ? 1 : 0;
}

static int print_double(FILE *primary, FILE *secondary, const char *key, int defined, double value)
{
    if (!defined || !isfinite(value)) {
        return write_both(primary, secondary, "%s=na\n", key);
    }
    return write_both(primary, secondary, "%s=%.17g\n", key, value);
}

static int read_effects(const char *path,
    double *effects,
    double *empty_medians,
    double *coverages,
    size_t capacity,
    size_t *count)
{
    FILE *file = fopen(path, "r");
    char line[LINE_CAPACITY];
    *count = 0u;
    if (file == NULL || fgets(line, sizeof(line), file) == NULL) {
        if (file != NULL) {
            (void)fclose(file);
        }
        return 1;
    }
    if (strstr(line, "effect_counts") == NULL) {
        (void)fclose(file);
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        double effect = 0.0;
        double empty_median = 0.0;
        double coverage = 1.0;
        char *cursor = line;
        if (*count >= capacity || line[0] == '\n' || line[0] == '\0') {
            (void)fclose(file);
            return 1;
        }
        effect = strtod(cursor, &cursor);
        if (*cursor != ',') {
            (void)fclose(file);
            return 1;
        }
        empty_median = strtod(cursor + 1, &cursor);
        if (*cursor == ',') {
            coverage = strtod(cursor + 1, &cursor);
        }
        effects[*count] = effect;
        empty_medians[*count] = empty_median;
        coverages[*count] = coverage;
        *count += 1u;
    }
    if (ferror(file) || fclose(file) != 0) {
        return 1;
    }
    return *count == 0u ? 1 : 0;
}

static int finish_file(FILE *file, int failed)
{
    if (failed) {
        (void)fclose(file);
        return 1;
    }
    return fclose(file) == 0 ? 0 : 1;
}

static int command_power(const char *csv_path, const char *directory, int development_phase)
{
    double effects[EFFECT_CAPACITY];
    double empty_medians[EFFECT_CAPACITY];
    double coverages[EFFECT_CAPACITY];
    size_t count = 0u;
    struct v4_power_plan plan;
    char path[1024];
    FILE *file;
    if (read_effects(csv_path, effects, empty_medians, coverages, EFFECT_CAPACITY, &count) != 0) {
        return 1;
    }
    v4_power_plan(effects, count, development_phase, &plan);
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nmode=power\nstatus=%s\nalpha_family=%.2f\npower_target=%.1f\n"
            "repeat_count=%u\nsession_count=%u\n",
            V4_PROTOCOL_ID,
            plan.status,
            V4_FAMILY_ALPHA,
            V4_POWER_TARGET,
            plan.repeat_count,
            plan.exported ? plan.session_count : 0u) != 0) {
        return finish_file(file, 1);
    }
    if (print_double(file,
            stdout,
            "development_mean_counts",
            count >= V4_SESSION_MIN,
            plan.development_mean_counts) != 0 ||
        print_double(file,
            stdout,
            "development_sd_counts",
            count >= V4_SESSION_MIN,
            plan.development_sd_counts) != 0 ||
        print_double(file, stdout, "power_at_exported", plan.exported, plan.power_at_exported) !=
            0 ||
        print_double(file,
            stdout,
            "power_at_previous",
            plan.exported && isfinite(plan.power_at_previous),
            plan.power_at_previous) != 0) {
        return finish_file(file, 1);
    }
    return finish_file(file, 0);
}

static int command_confirm(const char *csv_path, const char *directory, int enforce_coverage)
{
    double effects[EFFECT_CAPACITY];
    double empty_medians[EFFECT_CAPACITY];
    double coverages[EFFECT_CAPACITY];
    size_t count = 0u;
    struct v4_confirm_result result;
    char path[1024];
    FILE *file;
    FILE *table;
    if (read_effects(csv_path, effects, empty_medians, coverages, EFFECT_CAPACITY, &count) != 0) {
        return 1;
    }
    v4_confirm(effects, empty_medians, coverages, count, enforce_coverage, &result);
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nmode=confirm\nstatus=%s\nprimary_token=%s\n"
            "holm_family=message_zero_minus_message_ones\nalpha_family=%.2f\n"
            "holm_rejected=%s\ndirection_consistent=%s\nsession_count=%u\n",
            V4_PROTOCOL_ID,
            result.status,
            result.primary_token,
            V4_FAMILY_ALPHA,
            result.holm_rejected ? "yes" : "no",
            result.direction_consistent ? "yes" : "no",
            result.session_count) != 0) {
        return finish_file(file, 1);
    }
    if (print_double(file,
            stdout,
            "unadjusted_mean_counts",
            strcmp(result.status, "ok") == 0,
            result.unadjusted_mean_counts) != 0 ||
        print_double(file,
            stdout,
            "covariate_intercept_counts",
            strcmp(result.status, "ok") == 0,
            result.covariate_intercept_counts) != 0 ||
        print_double(file,
            stdout,
            "covariate_slope_counts",
            strcmp(result.status, "ok") == 0 && result.covariate_slope_defined,
            result.covariate_slope_counts) != 0 ||
        print_double(file,
            stdout,
            "covariate_slope_p_value",
            strcmp(result.status, "ok") == 0 && result.covariate_slope_defined,
            result.covariate_slope_p_value) != 0) {
        return finish_file(file, 1);
    }
    if (snprintf(path, sizeof(path), "%s/session-effects.csv", directory) >= (int)sizeof(path)) {
        return finish_file(file, 1);
    }
    table = fopen(path, "w");
    if (table == NULL ||
        fputs("session_index,effect_counts,empty_median_counts,window_coverage\n", table) < 0) {
        if (table != NULL) {
            (void)fclose(table);
        }
        return finish_file(file, 1);
    }
    for (size_t index = 0; index < count; ++index) {
        if (fprintf(table,
                "%zu,%.17g,%.17g,%.17g\n",
                index + 1u,
                effects[index],
                empty_medians[index],
                coverages[index]) < 0) {
            (void)fclose(table);
            return finish_file(file, 1);
        }
    }
    if (fclose(table) != 0) {
        return finish_file(file, 1);
    }
    return finish_file(file, 0);
}

static int command_paired(const char *csv_path, const char *directory)
{
    FILE *input = fopen(csv_path, "r");
    char line[LINE_CAPACITY];
    double branch_effects[V4_ALTERNATING_ROUNDS];
    double mask_effects[V4_ALTERNATING_ROUNDS];
    size_t count = 0u;
    struct v4_paired_result result;
    char path[1024];
    FILE *file;
    if (input == NULL || fgets(line, sizeof(line), input) == NULL) {
        if (input != NULL) {
            (void)fclose(input);
        }
        return 1;
    }
    while (fgets(line, sizeof(line), input) != NULL && count < V4_ALTERNATING_ROUNDS) {
        char *cursor = line;
        if (line[0] == '\n') {
            continue;
        }
        branch_effects[count] = strtod(cursor, &cursor);
        if (*cursor != ',') {
            (void)fclose(input);
            return 1;
        }
        mask_effects[count] = strtod(cursor + 1, &cursor);
        count += 1u;
    }
    if (ferror(input) || fclose(input) != 0) {
        return 1;
    }
    v4_paired(branch_effects, mask_effects, count, &result);
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nmode=paired\nverdict=%s\nholm_rejected=%s\n"
            "branch_direction_consistent=%s\nround_count=%u\n",
            V4_PROTOCOL_ID,
            result.verdict,
            result.holm_rejected ? "yes" : "no",
            result.branch_direction_consistent ? "yes" : "no",
            result.round_count) != 0 ||
        print_double(file,
            stdout,
            "mean_absolute_gap_counts",
            strcmp(result.verdict, "not_run") != 0,
            result.mean_absolute_gap_counts) != 0) {
        return finish_file(file, 1);
    }
    return finish_file(file, 0);
}

static int print_round_order(int hold_rule)
{
    for (unsigned round_number = 1u; round_number <= V4_ALTERNATING_ROUNDS; ++round_number) {
        int branch_first = hold_rule ? v4_hold_round_measures_branch_first(round_number)
                                     : v4_round_measures_branch_first(round_number);
        uint64_t seed =
            hold_rule ? v4_hold_alternating_seed(round_number) : v4_alternating_seed(round_number);
        const char *order = branch_first ? "branch_then_mask" : "mask_then_branch";
        if (printf("round=%u\norder=%s\nseed=%llu\n",
                round_number,
                order,
                (unsigned long long)seed) < 0) {
            return 1;
        }
    }
    return 0;
}

static int command_order(void)
{
    return print_round_order(0);
}

static int command_order_held(void)
{
    return print_round_order(1);
}

static int command_diagnose(const char *effect_path, const char *series_path, const char *directory)
{
    double effects[EFFECT_CAPACITY];
    double ignored_empty[EFFECT_CAPACITY];
    double ignored_coverage[EFFECT_CAPACITY];
    double series[4096];
    size_t effect_count = 0u;
    size_t series_count = 0u;
    double w_statistic = 0.0;
    double p_value = 0.0;
    double autocorrelation = 0.0;
    int shapiro_defined;
    int acf_defined = 0;
    char path[1024];
    FILE *file;
    FILE *series_file;
    if (read_effects(effect_path,
            effects,
            ignored_empty,
            ignored_coverage,
            EFFECT_CAPACITY,
            &effect_count) != 0) {
        return 1;
    }
    shapiro_defined = v4_shapiro_wilk(effects, effect_count, &w_statistic, &p_value) == 0;
    series_file = fopen(series_path, "r");
    if (series_file != NULL) {
        char line[LINE_CAPACITY];
        while (fgets(line, sizeof(line), series_file) != NULL && series_count < 4096u) {
            char *end = NULL;
            if (line[0] == '#' || strstr(line, "elapsed") != NULL) {
                continue;
            }
            series[series_count] = strtod(line, &end);
            if (end == line) {
                continue;
            }
            series_count += 1u;
        }
        acf_defined = ferror(series_file) == 0 && fclose(series_file) == 0 &&
            v4_lag1_autocorrelation(series, series_count, &autocorrelation) == 0;
    }
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nmode=diagnose\n"
            "qq_premise=sorted session effects are plotted against Blom normal quantiles\n"
            "shapiro_premise=the null hypothesis is that the session effects are normal\n"
            "acf_premise=lag-1 autocorrelation describes dependence inside one session and is "
            "not the session-level test\n",
            V4_PROTOCOL_ID) != 0 ||
        print_double(file, stdout, "shapiro_w", shapiro_defined, w_statistic) != 0 ||
        print_double(file, stdout, "shapiro_p_value", shapiro_defined, p_value) != 0 ||
        print_double(file, stdout, "acf_lag1", acf_defined, autocorrelation) != 0) {
        return finish_file(file, 1);
    }
    if (snprintf(path, sizeof(path), "%s/qq.svg", directory) >= (int)sizeof(path)) {
        return finish_file(file, 1);
    }
    {
        FILE *svg = fopen(path, "w");
        double sorted[EFFECT_CAPACITY];
        if (svg == NULL) {
            return finish_file(file, 1);
        }
        memcpy(sorted, effects, effect_count * sizeof(double));
        for (size_t index = 1; index < effect_count; ++index) {
            double current = sorted[index];
            size_t cursor = index;
            while (cursor > 0u && sorted[cursor - 1u] > current) {
                sorted[cursor] = sorted[cursor - 1u];
                cursor -= 1u;
            }
            sorted[cursor] = current;
        }
        if (fputs("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"640\" height=\"480\">\n",
                svg) < 0) {
            (void)fclose(svg);
            return finish_file(file, 1);
        }
        for (size_t index = 0; index < effect_count; ++index) {
            double quantile = 0.0;
            int x;
            int y;
            if (v4_blom_quantile(index, effect_count, &quantile) != 0) {
                (void)fclose(svg);
                return finish_file(file, 1);
            }
            x = 320 + (int)(quantile * 80.0);
            y = 240 - (int)(sorted[index] * 2.0);
            if (fprintf(svg, "<circle cx=\"%d\" cy=\"%d\" r=\"3\" fill=\"#1d4e89\"/>\n", x, y) <
                0) {
                (void)fclose(svg);
                return finish_file(file, 1);
            }
        }
        if (fputs("</svg>\n", svg) < 0 || fclose(svg) != 0) {
            return finish_file(file, 1);
        }
    }
    return finish_file(file, 0);
}

static int write_confirm_stop(const char *directory, const char *status, unsigned session_count)
{
    char path[1024];
    FILE *file;
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nmode=confirm\nstatus=%s\nprimary_token=not_run\n"
            "holm_family=message_zero_minus_message_ones\nalpha_family=%.2f\n"
            "holm_rejected=no\ndirection_consistent=no\nsession_count=%u\n",
            V4_PROTOCOL_ID,
            status,
            V4_FAMILY_ALPHA,
            session_count) != 0 ||
        print_double(file, stdout, "unadjusted_mean_counts", 0, 0.0) != 0 ||
        print_double(file, stdout, "covariate_intercept_counts", 0, 0.0) != 0 ||
        print_double(file, stdout, "covariate_slope_counts", 0, 0.0) != 0 ||
        print_double(file, stdout, "covariate_slope_p_value", 0, 0.0) != 0) {
        return finish_file(file, 1);
    }
    return finish_file(file, 0);
}

static int write_effect_table(const char *path,
    const double *effects,
    const double *empty_medians,
    const double *coverages,
    size_t count,
    int coverage_measured)
{
    FILE *table = fopen(path, "w");
    if (table == NULL || fputs("effect_counts,empty_median_counts,window_coverage\n", table) < 0) {
        if (table != NULL) {
            (void)fclose(table);
        }
        return 1;
    }
    for (size_t index = 0; index < count; ++index) {
        if (coverage_measured) {
            if (fprintf(table,
                    "%.17g,%.17g,%.17g\n",
                    effects[index],
                    empty_medians[index],
                    coverages[index]) < 0) {
                (void)fclose(table);
                return 1;
            }
        } else if (fprintf(table,
                       "%.17g,%.17g,unmeasured\n",
                       effects[index],
                       empty_medians[index]) < 0) {
            (void)fclose(table);
            return 1;
        }
    }
    return fclose(table) == 0 ? 0 : 1;
}

static int
command_confirm_sessions(const char *manifest_path, const char *directory, int enforce_coverage)
{
    double effects[EFFECT_CAPACITY];
    double empty_medians[EFFECT_CAPACITY];
    double coverages[EFFECT_CAPACITY];
    size_t count = 0u;
    const char *stop_status = NULL;
    char reduced_path[1024];
    if (v4_reduce_manifest(manifest_path,
            enforce_coverage,
            enforce_coverage,
            effects,
            empty_medians,
            coverages,
            EFFECT_CAPACITY,
            &count,
            &stop_status) != 0) {
        return 1;
    }
    if (stop_status != NULL) {
        return write_confirm_stop(directory, stop_status, (unsigned)count);
    }
    if (snprintf(reduced_path, sizeof(reduced_path), "%s/reduced-effects.csv", directory) >=
        (int)sizeof(reduced_path)) {
        return 1;
    }
    if (write_effect_table(reduced_path, effects, empty_medians, coverages, count, 1) != 0) {
        return 1;
    }
    return command_confirm(reduced_path, directory, enforce_coverage);
}

static int command_reduce_effects(const char *manifest_path, const char *csv_path, int development)
{
    double effects[EFFECT_CAPACITY];
    double empty_medians[EFFECT_CAPACITY];
    double coverages[EFFECT_CAPACITY];
    size_t count = 0u;
    const char *stop_status = NULL;
    if (v4_reduce_manifest(manifest_path,
            development ? 0 : 1,
            development ? 0 : 1,
            effects,
            empty_medians,
            coverages,
            EFFECT_CAPACITY,
            &count,
            &stop_status) != 0) {
        return 1;
    }
    if (stop_status != NULL) {
        if (printf("status=%s\nsession_count=%zu\n", stop_status, count) < 0) {
            return 1;
        }
        return 3;
    }
    if (write_effect_table(csv_path,
            effects,
            empty_medians,
            coverages,
            count,
            development ? 0 : 1) != 0) {
        return 1;
    }
    return printf("status=ok\nsession_count=%zu\n", count) < 0 ? 1 : 0;
}

static int command_label(unsigned block_number)
{
    uint32_t indices[V4_LABEL_DRAW_COUNT];
    if (v4_label_draw(block_number, indices) != 0) {
        return 1;
    }
    for (size_t index = 0; index < V4_LABEL_DRAW_COUNT; ++index) {
        if (printf("%u\n", indices[index]) < 0) {
            return 1;
        }
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fputs("usage: v4_analyze power|confirm|confirm-sessions|reduce-effects|paired|order|"
              "order-held|diagnose|label ...\n",
            stderr);
        return 1;
    }
    if (strcmp(argv[1], "power") == 0 && argc == 5) {
        int development_phase = strcmp(argv[4], "development") == 0;
        if (!development_phase && strcmp(argv[4], "fixture") != 0) {
            return 1;
        }
        return command_power(argv[2], argv[3], development_phase) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "confirm") == 0 && argc == 5) {
        int enforce_coverage = strcmp(argv[4], "confirmation") == 0;
        if (!enforce_coverage && strcmp(argv[4], "fixture") != 0) {
            return 1;
        }
        return command_confirm(argv[2], argv[3], enforce_coverage) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "confirm-sessions") == 0 && argc == 5) {
        int enforce_coverage = strcmp(argv[4], "confirmation") == 0;
        if (!enforce_coverage && strcmp(argv[4], "fixture") != 0) {
            return 1;
        }
        return command_confirm_sessions(argv[2], argv[3], enforce_coverage) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "reduce-effects") == 0 && argc == 5) {
        int development_phase = strcmp(argv[4], "development") == 0;
        int status;
        if (!development_phase && strcmp(argv[4], "confirmation") != 0) {
            return 1;
        }
        status = command_reduce_effects(argv[2], argv[3], development_phase);
        return status == 0 ? 0 : status;
    }
    if (strcmp(argv[1], "paired") == 0 && argc == 4) {
        return command_paired(argv[2], argv[3]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "order") == 0 && argc == 2) {
        return command_order();
    }
    if (strcmp(argv[1], "order-held") == 0 && argc == 2) {
        return command_order_held();
    }
    if (strcmp(argv[1], "diagnose") == 0 && argc == 5) {
        return command_diagnose(argv[2], argv[3], argv[4]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "label") == 0 && argc == 3) {
        char *end = NULL;
        unsigned long block_number = strtoul(argv[2], &end, 10);
        if (end == argv[2] || *end != '\0' || block_number > 6ul) {
            return 1;
        }
        return command_label((unsigned)block_number);
    }
    fputs("usage: v4_analyze power|confirm|confirm-sessions|reduce-effects|paired|order|"
          "order-held|diagnose|label ...\n",
        stderr);
    return 1;
}
