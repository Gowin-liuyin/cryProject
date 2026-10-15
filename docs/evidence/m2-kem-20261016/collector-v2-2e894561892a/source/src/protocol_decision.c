#define _POSIX_C_SOURCE 200809L

#include "protocol_decision.h"

#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

static int copy_token(char *destination, size_t capacity, const char *source)
{
    size_t length = strlen(source);
    if (length == 0u || length >= capacity) {
        return 1;
    }
    memcpy(destination, source, length + 1u);
    return 0;
}

static int parse_u64_list(const char *text, uint64_t *values, size_t capacity, size_t *count)
{
    char buffer[256];
    char *cursor;
    *count = 0u;
    if (copy_token(buffer, sizeof(buffer), text) != 0 && strlen(text) >= sizeof(buffer)) {
        return 1;
    }
    memcpy(buffer, text, strlen(text) + 1u);
    cursor = buffer;
    while (*cursor != '\0') {
        char *comma = strchr(cursor, ',');
        char *end = NULL;
        unsigned long long parsed;
        if (comma != NULL) {
            *comma = '\0';
        }
        if (*cursor == '\0') {
            return 1;
        }
        parsed = strtoull(cursor, &end, 10);
        if (end == cursor || *end != '\0' || *count >= capacity) {
            return 1;
        }
        values[*count] = (uint64_t)parsed;
        *count += 1u;
        if (comma == NULL) {
            break;
        }
        cursor = comma + 1;
    }
    return *count == 0u ? 1 : 0;
}

static int parse_comparisons(const char *text, struct frozen_protocol *protocol)
{
    char buffer[256];
    char *cursor;
    protocol->comparison_count = 0u;
    memcpy(buffer, text, strlen(text) + 1u);
    cursor = buffer;
    while (*cursor != '\0') {
        char *comma = strchr(cursor, ',');
        char *colon;
        struct protocol_comparison *comparison;
        if (comma != NULL) {
            *comma = '\0';
        }
        colon = strchr(cursor, ':');
        if (colon == NULL || protocol->comparison_count >= PROTOCOL_COMPARISON_CAPACITY) {
            return 1;
        }
        *colon = '\0';
        comparison = &protocol->comparisons[protocol->comparison_count];
        if (copy_token(comparison->left_category, sizeof(comparison->left_category), cursor) != 0 ||
            copy_token(comparison->right_category, sizeof(comparison->right_category), colon + 1) !=
                0) {
            return 1;
        }
        protocol->comparison_count += 1u;
        if (comma == NULL) {
            break;
        }
        cursor = comma + 1;
    }
    return protocol->comparison_count == 0u ? 1 : 0;
}

static int assign_key(struct frozen_protocol *protocol, const char *key, const char *value)
{
    if (strcmp(key, "protocol_id") == 0) {
        return copy_token(protocol->protocol_id, sizeof(protocol->protocol_id), value);
    }
    if (strcmp(key, "alpha_family") == 0) {
        protocol->alpha_family = strtod(value, NULL);
        return protocol->alpha_family <= 0.0 ? 1 : 0;
    }
    if (strcmp(key, "alpha_control") == 0) {
        return strcmp(value, "holm") == 0
            ? copy_token(protocol->alpha_control, sizeof(protocol->alpha_control), value)
            : 1;
    }
    if (strcmp(key, "analysis_unit") == 0) {
        return strcmp(value, "session") == 0
            ? copy_token(protocol->analysis_unit, sizeof(protocol->analysis_unit), value)
            : 1;
    }
    if (strcmp(key, "comparison_family") == 0) {
        return parse_comparisons(value, protocol);
    }
    if (strcmp(key, "primary_comparison") == 0) {
        char buffer[80];
        char *colon;
        memcpy(buffer, value, strlen(value) + 1u);
        colon = strchr(buffer, ':');
        if (colon == NULL) {
            return 1;
        }
        *colon = '\0';
        return copy_token(protocol->primary_left, sizeof(protocol->primary_left), buffer) != 0 ||
            copy_token(protocol->primary_right, sizeof(protocol->primary_right), colon + 1) != 0;
    }
    if (strcmp(key, "effect_direction") == 0) {
        return strcmp(value, "two_sided") == 0
            ? copy_token(protocol->effect_direction, sizeof(protocol->effect_direction), value)
            : 1;
    }
    if (strcmp(key, "effect_estimator") == 0) {
        return strcmp(value, "session_mean_difference") == 0
            ? copy_token(protocol->effect_estimator, sizeof(protocol->effect_estimator), value)
            : 1;
    }
    if (strcmp(key, "sample_budget_per_class") == 0) {
        protocol->sample_budget_per_class = strtoull(value, NULL, 10);
        return protocol->sample_budget_per_class == 0u ? 1 : 0;
    }
    if (strcmp(key, "session_budget") == 0) {
        protocol->session_budget = strtoull(value, NULL, 10);
        return protocol->session_budget == 0u ? 1 : 0;
    }
    if (strcmp(key, "block_lengths") == 0) {
        return parse_u64_list(value, protocol->block_lengths, 4u, &protocol->block_length_count);
    }
    if (strcmp(key, "autocorrelation_abs_limit") == 0) {
        protocol->autocorrelation_abs_limit = strtod(value, NULL);
        return 0;
    }
    if (strcmp(key, "anomaly_rule") == 0) {
        return strcmp(value, "keep_all_finite_nonnegative") == 0
            ? copy_token(protocol->anomaly_rule, sizeof(protocol->anomaly_rule), value)
            : 1;
    }
    if (strcmp(key, "interval") == 0) {
        return strcmp(value, "wald_95") == 0
            ? copy_token(protocol->interval_name, sizeof(protocol->interval_name), value)
            : 1;
    }
    if (strcmp(key, "stop_rule") == 0) {
        return strcmp(value, "fixed_budget") == 0
            ? copy_token(protocol->stop_rule, sizeof(protocol->stop_rule), value)
            : 1;
    }
    if (strcmp(key, "development_seeds") == 0) {
        return parse_u64_list(value,
            protocol->development_seeds,
            PROTOCOL_SEED_CAPACITY,
            &protocol->development_seed_count);
    }
    if (strcmp(key, "confirmation_seeds") == 0) {
        return parse_u64_list(value,
            protocol->confirmation_seeds,
            PROTOCOL_SEED_CAPACITY,
            &protocol->confirmation_seed_count);
    }
    if (strcmp(key, "iid_upgrade_allowed") == 0) {
        protocol->iid_upgrade_allowed = strcmp(value, "yes") == 0 ? 1 : 0;
        return strcmp(value, "yes") != 0 && strcmp(value, "no") != 0;
    }
    if (strcmp(key, "constant_time_upgrade_allowed") == 0) {
        protocol->constant_time_upgrade_allowed = strcmp(value, "yes") == 0 ? 1 : 0;
        return strcmp(value, "yes") != 0 && strcmp(value, "no") != 0;
    }
    if (strcmp(key, "thresholds_source") == 0) {
        return strcmp(value, "frozen_before_confirmation") == 0 ? 0 : 1;
    }
    return 0;
}

int protocol_load(const char *path, struct frozen_protocol *protocol)
{
    FILE *file = fopen(path, "r");
    char line[512];
    int saw_id = 0;
    int saw_family = 0;
    int saw_primary = 0;
    int saw_alpha = 0;
    if (file == NULL || protocol == NULL) {
        return 1;
    }
    memset(protocol, 0, sizeof(*protocol));
    while (fgets(line, sizeof(line), file) != NULL) {
        char *separator;
        char *newline = strchr(line, '\n');
        if (newline != NULL) {
            *newline = '\0';
        }
        if (line[0] == '\0' || line[0] == '#') {
            continue;
        }
        separator = strchr(line, '=');
        if (separator == NULL || separator == line) {
            (void)fclose(file);
            return 1;
        }
        *separator = '\0';
        if (assign_key(protocol, line, separator + 1) != 0) {
            (void)fclose(file);
            return 1;
        }
        if (strcmp(line, "protocol_id") == 0) {
            saw_id = 1;
        }
        if (strcmp(line, "comparison_family") == 0) {
            saw_family = 1;
        }
        if (strcmp(line, "primary_comparison") == 0) {
            saw_primary = 1;
        }
        if (strcmp(line, "alpha_family") == 0) {
            saw_alpha = 1;
        }
    }
    (void)fclose(file);
    if (!saw_id || !saw_family || !saw_primary || !saw_alpha || protocol->comparison_count == 0u ||
        protocol->block_length_count == 0u ||
        strcmp(protocol->comparisons[0].left_category, protocol->primary_left) != 0 ||
        strcmp(protocol->comparisons[0].right_category, protocol->primary_right) != 0 ||
        protocol->alpha_control[0] == '\0' || protocol->stop_rule[0] == '\0') {
        return 1;
    }
    return 0;
}

static double betacf(double shape_a, double shape_b, double fraction)
{
    const double tiny = 1e-300;
    const double epsilon = 3e-14;
    double qab = shape_a + shape_b;
    double qap = shape_a + 1.0;
    double qam = shape_a - 1.0;
    double continued_c = 1.0;
    double continued_d = 1.0 - qab * fraction / qap;
    double result;
    if (fabs(continued_d) < tiny) {
        continued_d = tiny;
    }
    continued_d = 1.0 / continued_d;
    result = continued_d;
    for (int term_index = 1; term_index <= 200; ++term_index) {
        int twice_index = 2 * term_index;
        double numerator = term_index * (shape_b - term_index) * fraction /
            ((qam + twice_index) * (shape_a + twice_index));
        double delta;
        continued_d = 1.0 + numerator * continued_d;
        if (fabs(continued_d) < tiny) {
            continued_d = tiny;
        }
        continued_c = 1.0 + numerator / continued_c;
        if (fabs(continued_c) < tiny) {
            continued_c = tiny;
        }
        continued_d = 1.0 / continued_d;
        result *= continued_d * continued_c;
        numerator = -(shape_a + term_index) * (qab + term_index) * fraction /
            ((shape_a + twice_index) * (qap + twice_index));
        continued_d = 1.0 + numerator * continued_d;
        if (fabs(continued_d) < tiny) {
            continued_d = tiny;
        }
        continued_c = 1.0 + numerator / continued_c;
        if (fabs(continued_c) < tiny) {
            continued_c = tiny;
        }
        continued_d = 1.0 / continued_d;
        delta = continued_d * continued_c;
        result *= delta;
        if (fabs(delta - 1.0) < epsilon) {
            break;
        }
    }
    return result;
}

static double regularized_beta(double shape_a, double shape_b, double fraction)
{
    double log_beta;
    double front;
    if (fraction <= 0.0) {
        return 0.0;
    }
    if (fraction >= 1.0) {
        return 1.0;
    }
    log_beta = lgamma(shape_a) + lgamma(shape_b) - lgamma(shape_a + shape_b);
    front = exp(shape_a * log(fraction) + shape_b * log(1.0 - fraction) - log_beta);
    if (fraction < (shape_a + 1.0) / (shape_a + shape_b + 2.0)) {
        return front * betacf(shape_a, shape_b, fraction) / shape_a;
    }
    return 1.0 - front * betacf(shape_b, shape_a, 1.0 - fraction) / shape_b;
}

double protocol_student_t_two_sided(double t_statistic, unsigned degrees_of_freedom)
{
    double absolute_t = fabs(t_statistic);
    double fraction;
    if (degrees_of_freedom == 0u) {
        return 1.0;
    }
    if (degrees_of_freedom == 1u) {
        return 1.0 - 2.0 * atan(absolute_t) / acos(-1.0);
    }
    fraction = (double)degrees_of_freedom / ((double)degrees_of_freedom + absolute_t * absolute_t);
    return regularized_beta(0.5 * (double)degrees_of_freedom, 0.5, fraction);
}

void protocol_holm(const double *p_values,
    size_t comparison_count,
    double alpha_family,
    int *rejected)
{
    size_t order[PROTOCOL_COMPARISON_CAPACITY];
    int still_rejecting = 1;
    for (size_t comparison_index = 0; comparison_index < comparison_count; ++comparison_index) {
        order[comparison_index] = comparison_index;
        rejected[comparison_index] = 0;
    }
    for (size_t left = 0; left + 1u < comparison_count; ++left) {
        for (size_t right = left + 1u; right < comparison_count; ++right) {
            if (p_values[order[right]] < p_values[order[left]]) {
                size_t swap = order[left];
                order[left] = order[right];
                order[right] = swap;
            }
        }
    }
    for (size_t rank = 0; rank < comparison_count; ++rank) {
        double threshold = alpha_family / (double)(comparison_count - rank);
        if (still_rejecting && p_values[order[rank]] <= threshold) {
            rejected[order[rank]] = 1;
        } else {
            still_rejecting = 0;
        }
    }
}

struct observation {
    char session_id[64];
    char category[32];
    char ciphertext_hex[80];
    uint64_t elapsed_counts;
};

static int split_csv_fields(char *line, char **fields, size_t field_count)
{
    size_t found = 0u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            *cursor = '\0';
            found += 1u;
            if (found >= field_count) {
                return 1;
            }
            fields[found] = cursor + 1;
        }
    }
    return found + 1u == field_count ? 0 : 1;
}

static int hex_repeats(const struct observation *rows,
    size_t row_count,
    const char *session_id,
    const char *category,
    double *repeat_rate)
{
    size_t count = 0u;
    size_t unique_count = 0u;
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        int seen = 0;
        if (strcmp(rows[row_index].session_id, session_id) != 0 ||
            strcmp(rows[row_index].category, category) != 0) {
            continue;
        }
        count += 1u;
        for (size_t earlier = 0; earlier < row_index; ++earlier) {
            if (strcmp(rows[earlier].session_id, session_id) == 0 &&
                strcmp(rows[earlier].category, category) == 0 &&
                strcmp(rows[earlier].ciphertext_hex, rows[row_index].ciphertext_hex) == 0) {
                seen = 1;
                break;
            }
        }
        if (!seen) {
            unique_count += 1u;
        }
    }
    if (count == 0u) {
        return 1;
    }
    *repeat_rate = (double)(count - unique_count) / (double)count;
    return 0;
}

static int category_mean(const struct observation *rows,
    size_t row_count,
    const char *session_id,
    const char *category,
    int use_blocks,
    uint64_t block_length,
    double *mean_counts,
    size_t *sample_count)
{
    double total = 0.0;
    size_t count = 0u;
    size_t block_count = 0u;
    double block_total = 0.0;
    size_t in_block = 0u;
    double block_mean_total = 0.0;
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        if (strcmp(rows[row_index].session_id, session_id) != 0 ||
            strcmp(rows[row_index].category, category) != 0) {
            continue;
        }
        total += (double)rows[row_index].elapsed_counts;
        count += 1u;
        if (use_blocks) {
            block_total += (double)rows[row_index].elapsed_counts;
            in_block += 1u;
            if (in_block == block_length) {
                block_mean_total += block_total / (double)block_length;
                block_count += 1u;
                block_total = 0.0;
                in_block = 0u;
            }
        }
    }
    *sample_count = count;
    if (!use_blocks) {
        if (count == 0u) {
            return 1;
        }
        *mean_counts = total / (double)count;
        return 0;
    }
    if (block_count == 0u) {
        return 1;
    }
    *mean_counts = block_mean_total / (double)block_count;
    return 0;
}

static double lag1_correlation(const struct observation *rows,
    size_t row_count,
    const char *session_id,
    const char *category,
    int *defined)
{
    double values[4096];
    size_t count = 0u;
    double mean;
    double variance = 0.0;
    double covariance = 0.0;
    *defined = 0;
    for (size_t row_index = 0; row_index < row_count && count < 4096u; ++row_index) {
        if (strcmp(rows[row_index].session_id, session_id) == 0 &&
            strcmp(rows[row_index].category, category) == 0) {
            values[count] = (double)rows[row_index].elapsed_counts;
            count += 1u;
        }
    }
    if (count < 3u) {
        return 0.0;
    }
    mean = 0.0;
    for (size_t value_index = 0; value_index < count; ++value_index) {
        mean += values[value_index];
    }
    mean /= (double)count;
    for (size_t value_index = 0; value_index < count; ++value_index) {
        double delta = values[value_index] - mean;
        variance += delta * delta;
    }
    if (variance == 0.0) {
        return 0.0;
    }
    for (size_t value_index = 1; value_index < count; ++value_index) {
        covariance += (values[value_index] - mean) * (values[value_index - 1u] - mean);
    }
    *defined = 1;
    return covariance / variance;
}

static int seed_is_listed(const uint64_t *seeds, size_t seed_count, uint64_t seed)
{
    for (size_t seed_index = 0; seed_index < seed_count; ++seed_index) {
        if (seeds[seed_index] == seed) {
            return 1;
        }
    }
    return 0;
}

int protocol_decide(const struct frozen_protocol *protocol,
    const char *csv_path,
    const char *phase,
    uint64_t seed,
    struct protocol_decision *decision,
    struct session_effect *session_effects,
    size_t session_capacity,
    size_t *session_count)
{
    static const char *header =
        "schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,"
        "category,generator_label,elapsed_clock_counts,clock_path,ciphertext_sha256_hex";
    FILE *file = fopen(csv_path, "r");
    char line[1024];
    struct observation *rows = NULL;
    size_t row_count = 0u;
    size_t row_capacity = 0u;
    char session_ids[64][64];
    size_t session_total = 0u;
    double primary_effects[64];
    double p_values[PROTOCOL_COMPARISON_CAPACITY];
    int rejected[PROTOCOL_COMPARISON_CAPACITY];
    int primary_index = -1;
    if (file == NULL || decision == NULL || session_count == NULL) {
        return 1;
    }
    memset(decision, 0, sizeof(*decision));
    decision->primary_p_value = nan("");
    if (strcmp(phase, "development") == 0 &&
        !seed_is_listed(protocol->development_seeds, protocol->development_seed_count, seed)) {
        (void)fclose(file);
        return 1;
    }
    if (strcmp(phase, "confirmation") == 0 &&
        !seed_is_listed(protocol->confirmation_seeds, protocol->confirmation_seed_count, seed)) {
        (void)fclose(file);
        return 1;
    }
    if (strcmp(phase, "numeric") != 0 && strcmp(phase, "development") != 0 &&
        strcmp(phase, "confirmation") != 0) {
        (void)fclose(file);
        return 1;
    }
    if (fgets(line, sizeof(line), file) == NULL) {
        (void)fclose(file);
        return 1;
    }
    line[strcspn(line, "\n")] = '\0';
    if (strcmp(line, header) != 0) {
        (void)fclose(file);
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *fields[12];
        char *end = NULL;
        struct observation observation;
        line[strcspn(line, "\n")] = '\0';
        if (split_csv_fields(line, fields, 12u) != 0 ||
            strcmp(fields[0], "session_decapsulation_v1") != 0) {
            free(rows);
            (void)fclose(file);
            return 1;
        }
        for (const char *digit = fields[9]; *digit != '\0'; ++digit) {
            if (!isdigit((unsigned char)*digit)) {
                free(rows);
                (void)fclose(file);
                return 1;
            }
        }
        memset(&observation, 0, sizeof(observation));
        if (copy_token(observation.session_id, sizeof(observation.session_id), fields[2]) != 0 ||
            copy_token(observation.category, sizeof(observation.category), fields[7]) != 0 ||
            copy_token(observation.ciphertext_hex,
                sizeof(observation.ciphertext_hex),
                fields[11]) != 0) {
            free(rows);
            (void)fclose(file);
            return 1;
        }
        observation.elapsed_counts = strtoull(fields[9], &end, 10);
        if (row_count == row_capacity) {
            size_t new_capacity = row_capacity == 0u ? 64u : row_capacity * 2u;
            struct observation *grown = realloc(rows, new_capacity * sizeof(*rows));
            if (grown == NULL) {
                free(rows);
                (void)fclose(file);
                return 1;
            }
            rows = grown;
            row_capacity = new_capacity;
        }
        rows[row_count] = observation;
        row_count += 1u;
    }
    (void)fclose(file);
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        int seen = 0;
        for (size_t session_index = 0; session_index < session_total; ++session_index) {
            if (strcmp(session_ids[session_index], rows[row_index].session_id) == 0) {
                seen = 1;
            }
        }
        if (!seen) {
            if (session_total >= 64u) {
                free(rows);
                return 1;
            }
            memcpy(session_ids[session_total], rows[row_index].session_id, 64u);
            session_total += 1u;
        }
    }
    if (strcmp(phase, "confirmation") == 0) {
        if (session_total < protocol->session_budget) {
            free(rows);
            return 1;
        }
        for (size_t session_index = 0; session_index < session_total; ++session_index) {
            for (size_t comparison_index = 0; comparison_index < protocol->comparison_count;
                ++comparison_index) {
                size_t left_count = 0u;
                size_t right_count = 0u;
                double ignored = 0.0;
                if (category_mean(rows,
                        row_count,
                        session_ids[session_index],
                        protocol->comparisons[comparison_index].left_category,
                        0,
                        1u,
                        &ignored,
                        &left_count) != 0 ||
                    left_count < protocol->sample_budget_per_class ||
                    category_mean(rows,
                        row_count,
                        session_ids[session_index],
                        protocol->comparisons[comparison_index].right_category,
                        0,
                        1u,
                        &ignored,
                        &right_count) != 0 ||
                    right_count < protocol->sample_budget_per_class) {
                    free(rows);
                    return 1;
                }
            }
        }
    }
    *session_count = 0u;
    for (size_t session_index = 0; session_index < session_total; ++session_index) {
        struct session_effect *effect;
        double left_mean = 0.0;
        double right_mean = 0.0;
        size_t left_count = 0u;
        size_t right_count = 0u;
        if (*session_count >= session_capacity) {
            free(rows);
            return 1;
        }
        effect = &session_effects[*session_count];
        memset(effect, 0, sizeof(*effect));
        memcpy(effect->session_id, session_ids[session_index], 64u);
        memcpy(effect->left_category, protocol->primary_left, sizeof(effect->left_category));
        memcpy(effect->right_category, protocol->primary_right, sizeof(effect->right_category));
        if (category_mean(rows,
                row_count,
                session_ids[session_index],
                protocol->primary_left,
                0,
                1u,
                &left_mean,
                &left_count) != 0 ||
            category_mean(rows,
                row_count,
                session_ids[session_index],
                protocol->primary_right,
                0,
                1u,
                &right_mean,
                &right_count) != 0) {
            free(rows);
            return 1;
        }
        effect->mean_difference_counts = left_mean - right_mean;
        effect->left_sample_count = left_count;
        effect->right_sample_count = right_count;
        effect->lag1_autocorrelation = lag1_correlation(rows,
            row_count,
            session_ids[session_index],
            protocol->primary_left,
            &effect->autocorrelation_defined);
        if (hex_repeats(rows,
                row_count,
                session_ids[session_index],
                protocol->primary_left,
                &effect->repeat_rate_left) != 0 ||
            hex_repeats(rows,
                row_count,
                session_ids[session_index],
                protocol->primary_right,
                &effect->repeat_rate_right) != 0) {
            free(rows);
            return 1;
        }
        primary_effects[*session_count] = effect->mean_difference_counts;
        *session_count += 1u;
    }
    if (*session_count == 0u) {
        free(rows);
        return 1;
    }
    {
        double total = 0.0;
        for (size_t session_index = 0; session_index < *session_count; ++session_index) {
            total += primary_effects[session_index];
        }
        decision->primary_mean_difference_counts = total / (double)(*session_count);
        decision->drift_last_minus_first =
            primary_effects[*session_count - 1u] - primary_effects[0];
    }
    if (*session_count < 2u) {
        decision->zero_variance = 1;
        decision->primary_p_defined = 0;
        decision->wald_low_counts = decision->primary_mean_difference_counts;
        decision->wald_high_counts = decision->primary_mean_difference_counts;
    } else {
        double variance = 0.0;
        for (size_t session_index = 0; session_index < *session_count; ++session_index) {
            double delta =
                primary_effects[session_index] - decision->primary_mean_difference_counts;
            variance += delta * delta;
        }
        variance /= (double)(*session_count - 1u);
        if (variance == 0.0) {
            decision->zero_variance = 1;
            decision->primary_p_defined = 0;
            decision->wald_low_counts = decision->primary_mean_difference_counts;
            decision->wald_high_counts = decision->primary_mean_difference_counts;
        } else {
            double standard_error = sqrt(variance / (double)(*session_count));
            decision->zero_variance = 0;
            decision->primary_p_defined = 1;
            decision->primary_t_statistic =
                decision->primary_mean_difference_counts / standard_error;
            decision->primary_p_value = protocol_student_t_two_sided(decision->primary_t_statistic,
                (unsigned)(*session_count - 1u));
            decision->wald_low_counts =
                decision->primary_mean_difference_counts - 1.959963984540054 * standard_error;
            decision->wald_high_counts =
                decision->primary_mean_difference_counts + 1.959963984540054 * standard_error;
        }
    }
    for (size_t comparison_index = 0; comparison_index < protocol->comparison_count;
        ++comparison_index) {
        double effects[64];
        double mean = 0.0;
        double variance = 0.0;
        if (strcmp(protocol->comparisons[comparison_index].left_category, protocol->primary_left) ==
                0 &&
            strcmp(protocol->comparisons[comparison_index].right_category,
                protocol->primary_right) == 0) {
            primary_index = (int)comparison_index;
        }
        for (size_t session_index = 0; session_index < session_total; ++session_index) {
            double left_mean = 0.0;
            double right_mean = 0.0;
            size_t ignored_count = 0u;
            if (category_mean(rows,
                    row_count,
                    session_ids[session_index],
                    protocol->comparisons[comparison_index].left_category,
                    0,
                    1u,
                    &left_mean,
                    &ignored_count) != 0 ||
                category_mean(rows,
                    row_count,
                    session_ids[session_index],
                    protocol->comparisons[comparison_index].right_category,
                    0,
                    1u,
                    &right_mean,
                    &ignored_count) != 0) {
                free(rows);
                return 1;
            }
            effects[session_index] = left_mean - right_mean;
            mean += effects[session_index];
        }
        mean /= (double)session_total;
        if (session_total < 2u) {
            p_values[comparison_index] = 1.0;
            continue;
        }
        for (size_t session_index = 0; session_index < session_total; ++session_index) {
            double delta = effects[session_index] - mean;
            variance += delta * delta;
        }
        variance /= (double)(session_total - 1u);
        if (variance == 0.0) {
            p_values[comparison_index] = 1.0;
        } else {
            double t_statistic = mean / sqrt(variance / (double)session_total);
            p_values[comparison_index] =
                protocol_student_t_two_sided(t_statistic, (unsigned)(session_total - 1u));
        }
    }
    protocol_holm(p_values, protocol->comparison_count, protocol->alpha_family, rejected);
    decision->holm_rejected_primary =
        primary_index >= 0 && rejected[primary_index] && decision->primary_p_defined ? 1 : 0;
    decision->block_length_count = protocol->block_length_count;
    for (size_t block_index = 0; block_index < protocol->block_length_count; ++block_index) {
        double total = 0.0;
        size_t used = 0u;
        uint64_t block_length = protocol->block_lengths[block_index];
        for (size_t session_index = 0; session_index < session_total; ++session_index) {
            double left_mean = 0.0;
            double right_mean = 0.0;
            size_t ignored_count = 0u;
            int use_blocks = block_length > 1u;
            if (category_mean(rows,
                    row_count,
                    session_ids[session_index],
                    protocol->primary_left,
                    use_blocks,
                    block_length,
                    &left_mean,
                    &ignored_count) != 0 ||
                category_mean(rows,
                    row_count,
                    session_ids[session_index],
                    protocol->primary_right,
                    use_blocks,
                    block_length,
                    &right_mean,
                    &ignored_count) != 0) {
                continue;
            }
            total += left_mean - right_mean;
            used += 1u;
        }
        decision->block_mean_difference[block_index] = used == 0u ? nan("") : total / (double)used;
    }
    {
        int autocorrelation_ok = 1;
        int repeat_ok = 1;
        for (size_t session_index = 0; session_index < *session_count; ++session_index) {
            if (!session_effects[session_index].autocorrelation_defined ||
                fabs(session_effects[session_index].lag1_autocorrelation) >
                    protocol->autocorrelation_abs_limit) {
                autocorrelation_ok = 0;
            }
            if (session_effects[session_index].repeat_rate_left > 0.0 ||
                session_effects[session_index].repeat_rate_right > 0.0) {
                repeat_ok = 0;
            }
        }
        if (protocol->iid_upgrade_allowed && autocorrelation_ok && repeat_ok) {
            memcpy(decision->iid_upgrade, "granted", 8u);
        } else {
            memcpy(decision->iid_upgrade, "refused", 8u);
        }
        if (protocol->constant_time_upgrade_allowed) {
            memcpy(decision->constant_time_upgrade, "granted", 8u);
        } else {
            memcpy(decision->constant_time_upgrade, "refused", 8u);
        }
    }
    memcpy(decision->thresholds_chosen_after_data, "no", 3u);
    free(rows);
    return 0;
}

int protocol_write_report(FILE *output,
    const char *phase,
    const struct protocol_decision *decision,
    const struct session_effect *session_effects,
    size_t session_count)
{
    if (fprintf(output,
            "phase=%s\nprimary_mean_difference_counts=%.17g\nprimary_t_statistic=%.17g\n",
            phase,
            decision->primary_mean_difference_counts,
            decision->primary_t_statistic) < 0) {
        return 1;
    }
    if (decision->primary_p_defined) {
        if (fprintf(output, "primary_p_value=%.17g\n", decision->primary_p_value) < 0) {
            return 1;
        }
    } else if (fprintf(output, "primary_p_value=undefined\n") < 0) {
        return 1;
    }
    if (fprintf(output,
            "primary_p_defined=%s\nholm_rejected_primary=%s\nzero_variance=%s\n"
            "wald_low_counts=%.17g\nwald_high_counts=%.17g\n"
            "drift_last_minus_first=%.17g\niid_upgrade=%s\nconstant_time_upgrade=%s\n"
            "repeat_ciphertext_reported=yes\nautocorrelation_reported=yes\n"
            "block_length_sensitivity_reported=yes\ndrift_reported=yes\n"
            "thresholds_chosen_after_data=%s\nstop_rule=fixed_budget\n",
            decision->primary_p_defined ? "yes" : "no",
            decision->holm_rejected_primary ? "yes" : "no",
            decision->zero_variance ? "yes" : "no",
            decision->wald_low_counts,
            decision->wald_high_counts,
            decision->drift_last_minus_first,
            decision->iid_upgrade,
            decision->constant_time_upgrade,
            decision->thresholds_chosen_after_data) < 0) {
        return 1;
    }
    for (size_t block_index = 0; block_index < decision->block_length_count; ++block_index) {
        if (fprintf(output,
                "block_mean_difference_%zu=%.17g\n",
                block_index,
                decision->block_mean_difference[block_index]) < 0) {
            return 1;
        }
    }
    for (size_t session_index = 0; session_index < session_count; ++session_index) {
        if (fprintf(output,
                "session_effect session_id=%s difference=%.17g\n",
                session_effects[session_index].session_id,
                session_effects[session_index].mean_difference_counts) < 0) {
            return 1;
        }
    }
    return 0;
}
