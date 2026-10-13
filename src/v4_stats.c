#include "v4_stats.h"

#include "protocol_decision.h"

#include <math.h>
#include <string.h>

uint64_t v4_development_seed(unsigned session_number)
{
    return UINT64_C(20261013000) + (uint64_t)session_number;
}

uint64_t v4_confirmation_seed(unsigned session_number)
{
    return UINT64_C(20261014000) + (uint64_t)session_number;
}

uint64_t v4_alternating_seed(unsigned round_number)
{
    return UINT64_C(20261015000) + (uint64_t)round_number;
}

/* 20261014 频率保持协议的种子。不替换上面 20261013 协议的种子。 */
uint64_t v4_hold_confirmation_seed(unsigned session_number)
{
    return V4_HOLD_CONFIRM_SEED_BASE + (uint64_t)session_number;
}

uint64_t v4_hold_alternating_seed(unsigned round_number)
{
    return V4_HOLD_ALTERNATING_SEED_BASE + (uint64_t)round_number;
}

uint64_t v4_splitmix64(uint64_t *state)
{
    uint64_t mixed = (*state += UINT64_C(0x9E3779B97F4A7C15));
    mixed = (mixed ^ (mixed >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    mixed = (mixed ^ (mixed >> 27)) * UINT64_C(0x94D049BB133111EB);
    return mixed ^ (mixed >> 31);
}

static int round_draws_branch_first(uint64_t order_seed, unsigned round_number)
{
    uint64_t state = order_seed;
    uint64_t draw = 0u;
    for (unsigned round_index = 1u; round_index <= round_number; ++round_index) {
        draw = v4_splitmix64(&state);
    }
    return (draw & 1u) == 0u;
}

int v4_round_measures_branch_first(unsigned round_number)
{
    return round_draws_branch_first(V4_ORDER_SEED, round_number);
}

int v4_hold_round_measures_branch_first(unsigned round_number)
{
    return round_draws_branch_first(V4_HOLD_ORDER_SEED, round_number);
}

int v4_mean_sd(const double *values, size_t count, double *mean_counts, double *sample_sd_counts)
{
    double sum = 0.0;
    double square_sum = 0.0;
    if (count == 0u) {
        return 1;
    }
    for (size_t index = 0; index < count; ++index) {
        sum += values[index];
    }
    *mean_counts = sum / (double)count;
    if (count == 1u) {
        *sample_sd_counts = 0.0;
        return 0;
    }
    for (size_t index = 0; index < count; ++index) {
        double centered = values[index] - *mean_counts;
        square_sum += centered * centered;
    }
    *sample_sd_counts = sqrt(square_sum / (double)(count - 1u));
    return 0;
}

int v4_one_sample_t(const double *values,
    size_t count,
    double *mean_counts,
    double *t_statistic,
    double *p_value,
    int *zero_variance)
{
    double sample_sd = 0.0;
    if (count < 2u || v4_mean_sd(values, count, mean_counts, &sample_sd) != 0) {
        return 1;
    }
    *zero_variance = sample_sd == 0.0;
    if (*zero_variance) {
        *t_statistic = 0.0;
        *p_value = *mean_counts == 0.0 ? 1.0 : 0.0;
        return 0;
    }
    *t_statistic = *mean_counts / (sample_sd / sqrt((double)count));
    *p_value = protocol_student_t_two_sided(*t_statistic, (unsigned)(count - 1u));
    return 0;
}

int v4_direction_consistent(const double *values, size_t count)
{
    int sign = 0;
    if (count == 0u) {
        return 0;
    }
    for (size_t index = 0; index < count; ++index) {
        int value_sign = values[index] > 0.0 ? 1 : (values[index] < 0.0 ? -1 : 0);
        if (value_sign == 0) {
            return 0;
        }
        if (sign == 0) {
            sign = value_sign;
        } else if (value_sign != sign) {
            return 0;
        }
    }
    return 1;
}

double v4_central_t_critical(double two_sided_alpha, unsigned degrees_of_freedom)
{
    double low = 0.0;
    double high = 1.0;
    if (degrees_of_freedom == 0u || two_sided_alpha <= 0.0 || two_sided_alpha >= 1.0) {
        return nan("");
    }
    while (protocol_student_t_two_sided(high, degrees_of_freedom) > two_sided_alpha) {
        high *= 2.0;
        if (high > 1.0e6) {
            return high;
        }
    }
    for (unsigned iteration = 0; iteration < 80u; ++iteration) {
        double mid = 0.5 * (low + high);
        if (protocol_student_t_two_sided(mid, degrees_of_freedom) > two_sided_alpha) {
            low = mid;
        } else {
            high = mid;
        }
    }
    return 0.5 * (low + high);
}

static double normal_survival(double z_score)
{
    return 0.5 * erfc(z_score / sqrt(2.0));
}

double v4_student_power(double mean_counts, double sample_sd_counts, unsigned session_count)
{
    unsigned degrees = session_count - 1u;
    double critical = v4_central_t_critical(V4_FAMILY_ALPHA, degrees);
    double noncentrality = fabs(mean_counts / sample_sd_counts) * sqrt((double)session_count);
    double upper = (double)degrees + 24.0 * sqrt(2.0 * (double)degrees);
    double lower = 1.0e-8;
    const int panel_count = 4096;
    double step = (upper - lower) / (double)panel_count;
    double density_mass = 0.0;
    double tail_mass = 0.0;
    double log_two = log(2.0);
    double log_gamma_half = lgamma(0.5 * (double)degrees);
    if (session_count < 2u || sample_sd_counts == 0.0 || !isfinite(critical)) {
        return nan("");
    }
    for (int panel_index = 0; panel_index <= panel_count; ++panel_index) {
        double variance = lower + step * (double)panel_index;
        double log_density = -0.5 * (double)degrees * log_two - log_gamma_half +
            (0.5 * (double)degrees - 1.0) * log(variance) - 0.5 * variance;
        double weight = exp(log_density);
        double scale = sqrt(variance / (double)degrees);
        double upper_tail = normal_survival(critical * scale - noncentrality);
        double lower_tail = 1.0 - normal_survival(-critical * scale - noncentrality);
        double simpson = 1.0;
        if (panel_index != 0 && panel_index != panel_count) {
            simpson = (panel_index % 2) == 0 ? 2.0 : 4.0;
        }
        density_mass += simpson * weight;
        tail_mass += simpson * weight * (upper_tail + lower_tail);
    }
    if (density_mass == 0.0) {
        return nan("");
    }
    return tail_mass / density_mass;
}

int v4_power_plan(const double *effects,
    size_t count,
    int require_development_count,
    struct v4_power_plan *plan)
{
    double mean_counts = 0.0;
    double sample_sd = 0.0;
    memset(plan, 0, sizeof(*plan));
    plan->status = "stopped_incomplete_development";
    plan->repeat_count = V4_DEVELOPMENT_REPEATS;
    if (require_development_count && count != V4_DEVELOPMENT_SESSIONS) {
        return 0;
    }
    if (count < V4_SESSION_MIN || v4_mean_sd(effects, count, &mean_counts, &sample_sd) != 0) {
        return 0;
    }
    plan->development_mean_counts = mean_counts;
    plan->development_sd_counts = sample_sd;
    if (sample_sd == 0.0 && mean_counts == 0.0) {
        plan->status = "stopped_no_stable_group_effect";
        return 0;
    }
    if (sample_sd == 0.0) {
        plan->status = "exported";
        plan->exported = 1;
        plan->session_count = V4_SESSION_MIN;
        plan->power_at_exported = 1.0;
        plan->power_at_previous = nan("");
        return 0;
    }
    if (mean_counts == 0.0) {
        plan->status = "stopped_no_stable_group_effect";
        return 0;
    }
    for (unsigned session_count = V4_SESSION_MIN; session_count <= V4_SESSION_MAX;
        ++session_count) {
        double power = v4_student_power(mean_counts, sample_sd, session_count);
        if (isfinite(power) && power >= V4_POWER_TARGET) {
            plan->status = "exported";
            plan->exported = 1;
            plan->session_count = session_count;
            plan->power_at_exported = power;
            plan->power_at_previous = session_count == V4_SESSION_MIN
                ? nan("")
                : v4_student_power(mean_counts, sample_sd, session_count - 1u);
            return 0;
        }
    }
    plan->status = "stopped_power_exceeds_cap";
    return 0;
}

int v4_centered_slope(const double *effects,
    const double *covariate,
    size_t count,
    double *intercept_counts,
    double *slope_counts,
    double *slope_p_value,
    int *slope_defined)
{
    double mean_effect = 0.0;
    double mean_covariate = 0.0;
    double product = 0.0;
    double square = 0.0;
    double residual_square = 0.0;
    if (count < 3u) {
        return 1;
    }
    for (size_t index = 0; index < count; ++index) {
        mean_effect += effects[index];
        mean_covariate += covariate[index];
    }
    mean_effect /= (double)count;
    mean_covariate /= (double)count;
    *intercept_counts = mean_effect;
    for (size_t index = 0; index < count; ++index) {
        double centered = covariate[index] - mean_covariate;
        product += centered * (effects[index] - mean_effect);
        square += centered * centered;
    }
    if (square == 0.0) {
        *slope_defined = 0;
        *slope_counts = 0.0;
        *slope_p_value = nan("");
        return 0;
    }
    *slope_defined = 1;
    *slope_counts = product / square;
    for (size_t index = 0; index < count; ++index) {
        double centered = covariate[index] - mean_covariate;
        double residual = effects[index] - (mean_effect + *slope_counts * centered);
        residual_square += residual * residual;
    }
    if (residual_square == 0.0) {
        *slope_p_value = *slope_counts == 0.0 ? 1.0 : 0.0;
        return 0;
    }
    {
        double residual_sd = sqrt(residual_square / (double)(count - 2u));
        double t_statistic = *slope_counts / (residual_sd / sqrt(square));
        *slope_p_value = protocol_student_t_two_sided(t_statistic, (unsigned)(count - 2u));
    }
    return 0;
}

int v4_confirm(const double *effects,
    const double *empty_medians,
    const double *coverages,
    size_t count,
    int enforce_coverage,
    struct v4_confirm_result *result)
{
    double mean_counts = 0.0;
    double t_statistic = 0.0;
    double p_value = 0.0;
    int zero_variance = 0;
    double holm_p = 0.0;
    int rejected = 0;
    memset(result, 0, sizeof(*result));
    result->status = "ok";
    result->primary_token = "not_run";
    result->session_count = (unsigned)count;
    if (count < V4_SESSION_MIN || count > V4_SESSION_MAX) {
        result->status = "stopped_session_count";
        return 0;
    }
    if (enforce_coverage) {
        for (size_t index = 0; index < count; ++index) {
            if (!isfinite(coverages[index]) || coverages[index] < V4_COVERAGE_THRESHOLD) {
                result->status = "stopped_window_coverage";
                return 0;
            }
        }
    }
    if (v4_one_sample_t(effects, count, &mean_counts, &t_statistic, &p_value, &zero_variance) !=
        0) {
        result->status = "stopped_undefined_effect";
        return 0;
    }
    holm_p = p_value;
    protocol_holm(&holm_p, 1u, V4_FAMILY_ALPHA, &rejected);
    result->holm_rejected = rejected;
    result->direction_consistent = v4_direction_consistent(effects, count);
    result->unadjusted_mean_counts = mean_counts;
    if (v4_centered_slope(effects,
            empty_medians,
            count,
            &result->covariate_intercept_counts,
            &result->covariate_slope_counts,
            &result->covariate_slope_p_value,
            &result->covariate_slope_defined) != 0) {
        result->status = "stopped_undefined_effect";
        result->primary_token = "not_run";
        return 0;
    }
    if (!rejected) {
        result->primary_token = "not_rejected";
    } else if (result->direction_consistent) {
        result->primary_token = "rejected_direction_consistent";
    } else {
        result->primary_token = "rejected_direction_inconsistent";
    }
    return 0;
}

int v4_paired(const double *branch_effects,
    const double *mask_effects,
    size_t round_count,
    struct v4_paired_result *result)
{
    double gaps[V4_ALTERNATING_ROUNDS];
    double mean_counts = 0.0;
    double t_statistic = 0.0;
    double p_value = 0.0;
    int zero_variance = 0;
    int rejected = 0;
    int every_gap_positive = 1;
    memset(result, 0, sizeof(*result));
    result->round_count = (unsigned)round_count;
    result->verdict = "not_run";
    if (round_count != V4_ALTERNATING_ROUNDS) {
        return 0;
    }
    for (size_t index = 0; index < round_count; ++index) {
        gaps[index] = fabs(branch_effects[index]) - fabs(mask_effects[index]);
        if (!(gaps[index] > 0.0)) {
            every_gap_positive = 0;
        }
    }
    if (v4_one_sample_t(gaps, round_count, &mean_counts, &t_statistic, &p_value, &zero_variance) !=
        0) {
        return 0;
    }
    protocol_holm(&p_value, 1u, V4_FAMILY_ALPHA, &rejected);
    result->holm_rejected = rejected;
    result->mean_absolute_gap_counts = mean_counts;
    result->branch_direction_consistent = v4_direction_consistent(branch_effects, round_count);
    if (rejected && mean_counts > 0.0 && every_gap_positive &&
        result->branch_direction_consistent) {
        result->verdict = "protection_causality";
    } else {
        result->verdict = "environment_drift_dominant";
    }
    return 0;
}

int v4_coverage_fraction(const uint64_t *frequency_khz,
    const uint64_t *time_ns,
    size_t sample_count,
    double *fraction)
{
    uint64_t inside_ns = 0u;
    uint64_t span_ns = 0u;
    if (sample_count < 2u) {
        return 1;
    }
    for (size_t index = 1; index < sample_count; ++index) {
        if (time_ns[index] < time_ns[index - 1u]) {
            return 1;
        }
    }
    span_ns = time_ns[sample_count - 1u] - time_ns[0];
    if (span_ns == 0u) {
        return 1;
    }
    for (size_t index = 0; index + 1u < sample_count; ++index) {
        if (frequency_khz[index] >= V4_BAND_LOW_KHZ && frequency_khz[index] <= V4_BAND_HIGH_KHZ) {
            inside_ns += time_ns[index + 1u] - time_ns[index];
        }
    }
    *fraction = (double)inside_ns / (double)span_ns;
    return 0;
}

double v4_even_median(const uint64_t *values, size_t count)
{
    uint64_t sorted[V4_EMPTY_WINDOW_COUNT];
    if (count == 0u || count > V4_EMPTY_WINDOW_COUNT || (count % 2u) != 0u) {
        return nan("");
    }
    memcpy(sorted, values, count * sizeof(uint64_t));
    for (size_t index = 1; index < count; ++index) {
        uint64_t current = sorted[index];
        size_t cursor = index;
        while (cursor > 0u && sorted[cursor - 1u] > current) {
            sorted[cursor] = sorted[cursor - 1u];
            cursor -= 1u;
        }
        sorted[cursor] = current;
    }
    return 0.5 * ((double)sorted[count / 2u - 1u] + (double)sorted[count / 2u]);
}

static double inverse_unit_normal(double probability)
{
    const double a1 = -3.969683028665376e+01;
    const double a2 = 2.209460984245205e+02;
    const double a3 = -2.759285104469687e+02;
    const double a4 = 1.383577518672690e+02;
    const double a5 = -3.066479806614716e+01;
    const double a6 = 2.506628277459239e+00;
    const double b1 = -5.447609879822406e+01;
    const double b2 = 1.615858368580409e+02;
    const double b3 = -1.556989798598866e+02;
    const double b4 = 6.680131188771972e+01;
    const double b5 = -1.328068155288572e+01;
    const double c1 = -7.784894002430293e-03;
    const double c2 = -3.223964580411365e-01;
    const double c3 = -2.400758277161838e+00;
    const double c4 = -2.549732539343734e+00;
    const double c5 = 4.374664141464968e+00;
    const double c6 = 2.938163982698783e+00;
    const double d1 = 7.784695709041462e-03;
    const double d2 = 3.224671290700398e-01;
    const double d3 = 2.445134137142996e+00;
    const double d4 = 3.754408661907416e+00;
    const double plow = 0.02425;
    double q;
    double r;
    if (!(probability > 0.0 && probability < 1.0)) {
        return nan("");
    }
    if (probability < plow) {
        q = sqrt(-2.0 * log(probability));
        return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
    }
    if (probability > 1.0 - plow) {
        q = sqrt(-2.0 * log(1.0 - probability));
        return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
    }
    q = probability - 0.5;
    r = q * q;
    return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
        (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0);
}

static double horner(double x, const double *coefficients, size_t count)
{
    double value = 0.0;
    for (size_t index = count; index > 0u; --index) {
        value = value * x + coefficients[index - 1u];
    }
    return value;
}

int v4_shapiro_wilk(const double *values, size_t count, double *w_statistic, double *p_value)
{
    double sorted[V4_SESSION_MAX];
    double weight[V4_SESSION_MAX];
    double axis = 0.0;
    double square = 0.0;
    double weighted = 0.0;
    size_t half;
    const double c1[] = {0.0, 0.221157, -0.147981, -2.07119, 4.434685, -2.706056};
    const double c2[] = {0.0, 0.042981, -0.293762, -1.752461, 5.682633, -3.582633};
    const double c3[] = {0.5440, -0.39978, 0.025054, -0.0006714};
    const double c4[] = {1.3822, -0.77857, 0.062767, -0.0020322};
    const double c5[] = {-1.5861, -0.31082, -0.083751, 0.0038915};
    const double c6[] = {-0.4803, -0.082676, 0.0030302};
    const double g_coef[] = {-2.273, 0.459};
    if (count < 3u || count > V4_SESSION_MAX) {
        return 1;
    }
    memcpy(sorted, values, count * sizeof(double));
    for (size_t index = 1; index < count; ++index) {
        double current = sorted[index];
        size_t cursor = index;
        while (cursor > 0u && sorted[cursor - 1u] > current) {
            sorted[cursor] = sorted[cursor - 1u];
            cursor -= 1u;
        }
        sorted[cursor] = current;
    }
    if (sorted[count - 1u] - sorted[0] == 0.0) {
        return 1;
    }
    if (count == 3u) {
        weight[0] = sqrt(0.5);
        weight[1] = 0.0;
        weight[2] = -sqrt(0.5);
    } else {
        double moment = 0.0;
        double scale_x = 1.0 / sqrt((double)count);
        double first;
        double second = 0.0;
        double phi;
        half = count / 2u;
        for (size_t index = 0; index < half; ++index) {
            double probability = ((double)index + 1.0 - 0.375) / ((double)count + 0.25);
            weight[index] = -inverse_unit_normal(probability);
            moment += 2.0 * weight[index] * weight[index];
        }
        first = weight[0] / sqrt(moment) + horner(scale_x, c1, 6u);
        if (count <= 5u) {
            phi = (moment - 2.0 * weight[0] * weight[0]) / (1.0 - 2.0 * first * first);
            for (size_t index = 0; index < half; ++index) {
                weight[index] /= sqrt(phi);
            }
            weight[0] = first;
        } else {
            second = weight[1] / sqrt(moment) + horner(scale_x, c2, 6u);
            phi = (moment - 2.0 * weight[0] * weight[0] - 2.0 * weight[1] * weight[1]) /
                (1.0 - 2.0 * first * first - 2.0 * second * second);
            for (size_t index = 0; index < half; ++index) {
                weight[index] /= sqrt(phi);
            }
            weight[0] = first;
            weight[1] = second;
        }
        for (size_t index = 0; index < half; ++index) {
            weight[count - 1u - index] = -weight[index];
        }
        if ((count % 2u) != 0u) {
            weight[half] = 0.0;
        }
    }
    for (size_t index = 0; index < count; ++index) {
        axis += sorted[index];
        weighted += weight[index] * sorted[index];
    }
    axis /= (double)count;
    for (size_t index = 0; index < count; ++index) {
        double centered = sorted[index] - axis;
        square += centered * centered;
    }
    *w_statistic = weighted * weighted / square;
    if (*w_statistic < 0.0) {
        *w_statistic = 0.0;
    }
    if (*w_statistic > 1.0) {
        *w_statistic = 1.0;
    }
    if (count == 3u) {
        *p_value = 1.0 - 6.0 * acos(sqrt(*w_statistic)) / acos(-1.0);
        return 0;
    }
    if (count <= 11u) {
        double gamma = horner((double)count, g_coef, 2u);
        double transformed = -log(gamma - log(1.0 - *w_statistic));
        double center = horner((double)count, c3, 4u);
        double spread = exp(horner((double)count, c4, 4u));
        *p_value = normal_survival((transformed - center) / spread);
        return 0;
    }
    {
        double transformed = log(1.0 - *w_statistic);
        double center = horner(log((double)count), c5, 4u);
        double spread = exp(horner(log((double)count), c6, 3u));
        *p_value = normal_survival((transformed - center) / spread);
    }
    return 0;
}

int v4_lag1_autocorrelation(const double *values, size_t count, double *autocorrelation)
{
    double mean_counts = 0.0;
    double variance = 0.0;
    double product = 0.0;
    if (count < 3u) {
        return 1;
    }
    for (size_t index = 0; index < count; ++index) {
        mean_counts += values[index];
    }
    mean_counts /= (double)count;
    for (size_t index = 0; index < count; ++index) {
        double centered = values[index] - mean_counts;
        variance += centered * centered;
        if (index + 1u < count) {
            product += centered * (values[index + 1u] - mean_counts);
        }
    }
    if (variance == 0.0) {
        return 1;
    }
    *autocorrelation = product / variance;
    return 0;
}

int v4_label_draw(unsigned block_number, uint32_t indices[V4_LABEL_DRAW_COUNT])
{
    uint32_t pool[V4_LABEL_POPULATION];
    uint64_t state;
    if (block_number < 1u || block_number > 6u) {
        return 1;
    }
    state = V4_LABEL_SEED + (uint64_t)block_number;
    (void)v4_splitmix64(&state);
    for (uint32_t index = 0; index < V4_LABEL_POPULATION; ++index) {
        pool[index] = index;
    }
    for (uint32_t draw_index = 0; draw_index < V4_LABEL_DRAW_COUNT; ++draw_index) {
        uint64_t draw = v4_splitmix64(&state);
        uint32_t remaining = V4_LABEL_POPULATION - draw_index;
        uint32_t selected = draw_index + (uint32_t)(draw % remaining);
        uint32_t swap = pool[draw_index];
        pool[draw_index] = pool[selected];
        pool[selected] = swap;
        indices[draw_index] = pool[draw_index];
    }
    return 0;
}

int v4_blom_quantile(size_t order_index, size_t count, double *quantile)
{
    double probability;
    if (count == 0u || order_index >= count) {
        return 1;
    }
    probability = ((double)order_index + 1.0 - 0.375) / ((double)count + 0.25);
    *quantile = inverse_unit_normal(probability);
    return 0;
}
