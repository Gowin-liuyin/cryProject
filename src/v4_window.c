#define _POSIX_C_SOURCE 200809L
#ifdef __linux__
#define _GNU_SOURCE
#endif

#include "v4_stats.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#ifdef __linux__
#include <sys/wait.h>
#endif

#ifdef __linux__
static int read_text(const char *path, char *buffer, size_t capacity)
{
    FILE *file = fopen(path, "r");
    if (file == NULL || fgets(buffer, (int)capacity, file) == NULL) {
        if (file != NULL) {
            (void)fclose(file);
        }
        return 1;
    }
    buffer[strcspn(buffer, "\n")] = '\0';
    return fclose(file) == 0 ? 0 : 1;
}

static int write_text(const char *path, const char *text)
{
    FILE *file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (fprintf(file, "%s\n", text) < 0 || fclose(file) != 0) {
        return 1;
    }
    return 0;
}

static int cpu_frequency_path(unsigned cpu_index, const char *field, char *path, size_t capacity)
{
    return snprintf(path, capacity, "/sys/devices/system/cpu/cpu%u/cpufreq/%s", cpu_index, field) >=
        (int)capacity;
}
#endif

static int coverage_self_check(void)
{
    uint64_t times[10];
    uint64_t inside[10];
    uint64_t mixed[10];
    double fraction = 0.0;
    for (size_t index = 0; index < 10u; ++index) {
        times[index] = index * UINT64_C(1000000);
        inside[index] = 4300000u;
        mixed[index] = 4300000u;
    }
    mixed[0] = 1000000u;
    if (v4_coverage_fraction(inside, times, 10u, &fraction) != 0 || fraction != 1.0) {
        return 1;
    }
    if (v4_coverage_fraction(mixed, times, 10u, &fraction) != 0) {
        return 1;
    }
    return fraction == 8.0 / 9.0 ? 0 : 1;
}

/* 兄弟列表必须恰好是两个逻辑 CPU。范围写法只接受相邻的一对。 */
static int parse_exact_sibling(const char *text, unsigned self_cpu, unsigned *sibling_cpu)
{
    unsigned first = 0u;
    unsigned second = 0u;
    char separator = '\0';
    char trailing = '\0';
    int comma_count = 0;
    int hyphen_count = 0;
    int converted;
    if (text == NULL || text[0] == '\0') {
        return 1;
    }
    for (size_t index = 0; text[index] != '\0'; ++index) {
        if (text[index] == ',') {
            comma_count += 1;
        } else if (text[index] == '-') {
            hyphen_count += 1;
        } else if (text[index] < '0' || text[index] > '9') {
            return 1;
        }
    }
    if (comma_count + hyphen_count != 1) {
        return 1;
    }
    converted = sscanf(text, "%u%c%u%c", &first, &separator, &second, &trailing);
    if (converted != 3) {
        return 1;
    }
    if (hyphen_count == 1 && second != first + 1u) {
        return 1;
    }
    if (first == self_cpu && second != self_cpu && second <= 31u) {
        *sibling_cpu = second;
        return 0;
    }
    if (second == self_cpu && first != self_cpu && first <= 31u) {
        *sibling_cpu = first;
        return 0;
    }
    return 1;
}

static int sibling_self_check(void)
{
    unsigned sibling_cpu = 0u;
    if (parse_exact_sibling("2,18", 2u, &sibling_cpu) != 0 || sibling_cpu != 18u) {
        return 1;
    }
    if (parse_exact_sibling("18,2", 2u, &sibling_cpu) != 0 || sibling_cpu != 18u) {
        return 1;
    }
    if (parse_exact_sibling("2-3", 2u, &sibling_cpu) != 0 || sibling_cpu != 3u) {
        return 1;
    }
    if (parse_exact_sibling("2", 2u, &sibling_cpu) == 0 ||
        parse_exact_sibling("2,18,19", 2u, &sibling_cpu) == 0 ||
        parse_exact_sibling("0-31", 2u, &sibling_cpu) == 0 ||
        parse_exact_sibling("2,2", 2u, &sibling_cpu) == 0) {
        return 1;
    }
    return 0;
}

static int frequency_in_band(uint64_t frequency_khz)
{
    return frequency_khz >= V4_BAND_LOW_KHZ && frequency_khz <= V4_BAND_HIGH_KHZ;
}

/* 连续 streak 次带内才算请求已经落地。带外读数把连续计数清零。 */
static int precondition_streak_ready(const uint64_t *frequency_khz, size_t count, unsigned streak)
{
    unsigned consecutive_in_band = 0u;
    if (frequency_khz == NULL || streak == 0u) {
        return 0;
    }
    for (size_t index = 0; index < count; ++index) {
        if (frequency_in_band(frequency_khz[index])) {
            consecutive_in_band += 1u;
            if (consecutive_in_band >= streak) {
                return 1;
            }
        } else {
            consecutive_in_band = 0u;
        }
    }
    return 0;
}

static int hold_policy_self_check(void)
{
    uint64_t ready[3];
    uint64_t broken[5];
    uint64_t late[4];
    uint64_t outside[2];
    ready[0] = 4257000ull;
    ready[1] = 4300000ull;
    ready[2] = 4343000ull;
    broken[0] = 4300000ull;
    broken[1] = 4300000ull;
    broken[2] = 4256999ull;
    broken[3] = 4300000ull;
    broken[4] = 4300000ull;
    late[0] = 1000000ull;
    late[1] = 4300000ull;
    late[2] = 4300000ull;
    late[3] = 4300000ull;
    outside[0] = 4256999ull;
    outside[1] = 4343001ull;
    if (strcmp(V4_HOLD_RULE_ID, "v4_frequency_hold_20261014") != 0 ||
        strcmp(V4_HOLD_GOVERNOR, "performance") != 0 || strcmp(V4_HOLD_EPP, "performance") != 0 ||
        strcmp(V4_HOLD_BOOST, "0") != 0 || strcmp(V4_HOLD_FREQ_KHZ, "4300000") != 0) {
        return 1;
    }
    if (V4_COVERAGE_THRESHOLD != 0.99 || V4_BAND_LOW_KHZ != 4257000ull ||
        V4_BAND_HIGH_KHZ != 4343000ull || V4_HOLD_PRECONDITION_STREAK != 3u ||
        V4_HOLD_PRECONDITION_LIMIT != 100u) {
        return 1;
    }
    if (!precondition_streak_ready(ready, 3u, V4_HOLD_PRECONDITION_STREAK) ||
        precondition_streak_ready(ready, 2u, V4_HOLD_PRECONDITION_STREAK) ||
        precondition_streak_ready(broken, 5u, V4_HOLD_PRECONDITION_STREAK) ||
        !precondition_streak_ready(late, 4u, V4_HOLD_PRECONDITION_STREAK) ||
        precondition_streak_ready(outside, 2u, V4_HOLD_PRECONDITION_STREAK)) {
        return 1;
    }
    return 0;
}

#ifdef __linux__
static int copy_cpu_stat(FILE *output, unsigned cpu_index, const char *phase)
{
    FILE *stat_file = fopen("/proc/stat", "r");
    char line[512];
    char prefix[32];
    int found = 0;
    if (stat_file == NULL ||
        snprintf(prefix, sizeof(prefix), "cpu%u ", cpu_index) >= (int)sizeof(prefix)) {
        if (stat_file != NULL) {
            (void)fclose(stat_file);
        }
        return 1;
    }
    while (fgets(line, sizeof(line), stat_file) != NULL) {
        if (strncmp(line, prefix, strlen(prefix)) == 0) {
            if (fprintf(output, "phase=%s %s", phase, line) < 0) {
                found = 0;
                break;
            }
            found = 1;
            break;
        }
    }
    if (fclose(stat_file) != 0) {
        return 1;
    }
    return found ? 0 : 1;
}

static int frequencies_match_baseline(const unsigned cpus[2],
    char baseline_min[2][64],
    char baseline_max[2][64])
{
    for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
        char path[256];
        char current[64];
        if (cpu_frequency_path(cpus[cpu_slot], "scaling_min_freq", path, sizeof(path)) != 0 ||
            read_text(path, current, sizeof(current)) != 0 ||
            strcmp(current, baseline_min[cpu_slot]) != 0) {
            return 1;
        }
        if (cpu_frequency_path(cpus[cpu_slot], "scaling_max_freq", path, sizeof(path)) != 0 ||
            read_text(path, current, sizeof(current)) != 0 ||
            strcmp(current, baseline_max[cpu_slot]) != 0) {
            return 1;
        }
    }
    return 0;
}

#define V4_BOOST_PATH "/sys/devices/system/cpu/cpufreq/boost"

static int read_cpu_field(unsigned cpu_index, const char *field, char *buffer, size_t capacity)
{
    char path[256];
    if (cpu_frequency_path(cpu_index, field, path, sizeof(path)) != 0) {
        return 1;
    }
    return read_text(path, buffer, capacity);
}

static int write_cpu_field(unsigned cpu_index, const char *field, const char *text)
{
    char path[256];
    if (cpu_frequency_path(cpu_index, field, path, sizeof(path)) != 0) {
        return 1;
    }
    return write_text(path, text);
}

static int hold_requests_match(const unsigned cpus[2])
{
    char text[64];
    if (read_text(V4_BOOST_PATH, text, sizeof(text)) != 0 || strcmp(text, V4_HOLD_BOOST) != 0) {
        return 1;
    }
    for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
        if (read_cpu_field(cpus[cpu_slot], "scaling_governor", text, sizeof(text)) != 0 ||
            strcmp(text, V4_HOLD_GOVERNOR) != 0 ||
            read_cpu_field(cpus[cpu_slot], "energy_performance_preference", text, sizeof(text)) !=
                0 ||
            strcmp(text, V4_HOLD_EPP) != 0 ||
            read_cpu_field(cpus[cpu_slot], "scaling_min_freq", text, sizeof(text)) != 0 ||
            strcmp(text, V4_HOLD_FREQ_KHZ) != 0 ||
            read_cpu_field(cpus[cpu_slot], "scaling_max_freq", text, sizeof(text)) != 0 ||
            strcmp(text, V4_HOLD_FREQ_KHZ) != 0) {
            return 1;
        }
    }
    return 0;
}

static int hold_baseline_matches(const unsigned cpus[2],
    const char baseline_governor[2][64],
    const char baseline_epp[2][64],
    const char *baseline_boost)
{
    char text[64];
    if (read_text(V4_BOOST_PATH, text, sizeof(text)) != 0 || strcmp(text, baseline_boost) != 0) {
        return 1;
    }
    for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
        if (read_cpu_field(cpus[cpu_slot], "scaling_governor", text, sizeof(text)) != 0 ||
            strcmp(text, baseline_governor[cpu_slot]) != 0 ||
            read_cpu_field(cpus[cpu_slot], "energy_performance_preference", text, sizeof(text)) !=
                0 ||
            strcmp(text, baseline_epp[cpu_slot]) != 0) {
            return 1;
        }
    }
    return 0;
}
#endif

int main(int argc, char **argv)
{
    if (argc == 2 && strcmp(argv[1], "--coverage-self-check") == 0) {
        return coverage_self_check();
    }
    if (argc == 2 && strcmp(argv[1], "--sibling-self-check") == 0) {
        return sibling_self_check();
    }
    if (argc == 2 && strcmp(argv[1], "--hold-policy-self-check") == 0) {
        return hold_policy_self_check();
    }
#ifndef __linux__
    fputs("v4_window run requires linux\n", stderr);
    return 2;
#else
    char sibling_text[128];
    char baseline_min[2][64];
    char baseline_max[2][64];
    char baseline_governor[2][64] = {{0}};
    char baseline_epp[2][64] = {{0}};
    char baseline_boost[64] = "";
    unsigned cpus[2];
    unsigned sibling = 0u;
    pid_t child = -1;
    int child_status = 0;
    int hold_requested = 0;
    int frequency_requested = 0;
    int exit_status = 1;
    int child_started = 0;
    unsigned precondition_count = 0u;
    FILE *sample_file = NULL;
    FILE *smt_file = NULL;
    if (argc < 4 || (strcmp(argv[1], "run") != 0 && strcmp(argv[1], "run-held") != 0)) {
        fputs("usage: v4_window run|run-held OUTDIR -- collector args\n", stderr);
        return 1;
    }
    hold_requested = strcmp(argv[1], "run-held") == 0;
    if (geteuid() != 0) {
        fputs("status=not_root\n", stdout);
        return 2;
    }
    cpus[0] = 2u;
    if (read_text("/sys/devices/system/cpu/cpu2/topology/thread_siblings_list",
            sibling_text,
            sizeof(sibling_text)) != 0 ||
        parse_exact_sibling(sibling_text, 2u, &sibling) != 0) {
        fputs("status=stopped_sibling_list\n", stdout);
        return 2;
    }
    cpus[1] = sibling;
    for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
        char path[256];
        if (cpu_frequency_path(cpus[cpu_slot], "scaling_min_freq", path, sizeof(path)) != 0 ||
            read_text(path, baseline_min[cpu_slot], sizeof(baseline_min[cpu_slot])) != 0 ||
            cpu_frequency_path(cpus[cpu_slot], "scaling_max_freq", path, sizeof(path)) != 0 ||
            read_text(path, baseline_max[cpu_slot], sizeof(baseline_max[cpu_slot])) != 0) {
            return 2;
        }
    }
    if (hold_requested) {
        if (read_text(V4_BOOST_PATH, baseline_boost, sizeof(baseline_boost)) != 0) {
            fputs("status=stopped_boost_file\n", stdout);
            return 3;
        }
        for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
            if (read_cpu_field(cpus[cpu_slot],
                    "scaling_governor",
                    baseline_governor[cpu_slot],
                    sizeof(baseline_governor[cpu_slot])) != 0 ||
                read_cpu_field(cpus[cpu_slot],
                    "energy_performance_preference",
                    baseline_epp[cpu_slot],
                    sizeof(baseline_epp[cpu_slot])) != 0) {
                fputs("status=stopped_policy_baseline\n", stdout);
                return 3;
            }
        }
    }
    {
        char path[512];
        FILE *baseline = NULL;
        if (snprintf(path, sizeof(path), "%s/frequency-baseline.txt", argv[2]) >=
            (int)sizeof(path)) {
            return 1;
        }
        baseline = fopen(path, "w");
        if (baseline == NULL) {
            return 1;
        }
        if (hold_requested &&
            fprintf(baseline, "hold_rule_id=%s\nboost=%s\n", V4_HOLD_RULE_ID, baseline_boost) < 0) {
            (void)fclose(baseline);
            return 1;
        }
        for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
            if (fprintf(baseline,
                    "cpu=%u\nmin=%s\nmax=%s\n",
                    cpus[cpu_slot],
                    baseline_min[cpu_slot],
                    baseline_max[cpu_slot]) < 0) {
                (void)fclose(baseline);
                return 1;
            }
            if (hold_requested &&
                fprintf(baseline,
                    "governor=%s\nepp=%s\n",
                    baseline_governor[cpu_slot],
                    baseline_epp[cpu_slot]) < 0) {
                (void)fclose(baseline);
                return 1;
            }
        }
        if (fclose(baseline) != 0) {
            return 1;
        }
    }
    frequency_requested = 1;
    if (hold_requested && write_text(V4_BOOST_PATH, V4_HOLD_BOOST) != 0) {
        goto restore;
    }
    for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
        char path[256];
        if (cpu_frequency_path(cpus[cpu_slot], "scaling_min_freq", path, sizeof(path)) != 0 ||
            write_text(path, "4300000") != 0 ||
            cpu_frequency_path(cpus[cpu_slot], "scaling_max_freq", path, sizeof(path)) != 0 ||
            write_text(path, "4300000") != 0) {
            goto restore;
        }
    }
    if (hold_requested) {
        char readback_path[512];
        FILE *readback = NULL;
        int requests_match = 0;
        char seen_boost[64];
        for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
            if (write_cpu_field(cpus[cpu_slot], "scaling_governor", V4_HOLD_GOVERNOR) != 0 ||
                write_cpu_field(cpus[cpu_slot], "energy_performance_preference", V4_HOLD_EPP) !=
                    0) {
                goto restore;
            }
        }
        requests_match = hold_requests_match(cpus) == 0;
        if (snprintf(readback_path, sizeof(readback_path), "%s/policy-readback.txt", argv[2]) <
            (int)sizeof(readback_path)) {
            readback = fopen(readback_path, "w");
        }
        if (readback != NULL) {
            if (read_text(V4_BOOST_PATH, seen_boost, sizeof(seen_boost)) != 0) {
                seen_boost[0] = '\0';
            }
            (void)fprintf(readback,
                "boost=%s\nmatch=%s\n",
                seen_boost,
                requests_match ? "yes" : "no");
            for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
                char governor[64];
                char epp[64];
                char minimum[64];
                char maximum[64];
                governor[0] = '\0';
                epp[0] = '\0';
                minimum[0] = '\0';
                maximum[0] = '\0';
                (void)
                    read_cpu_field(cpus[cpu_slot], "scaling_governor", governor, sizeof(governor));
                (void)read_cpu_field(cpus[cpu_slot],
                    "energy_performance_preference",
                    epp,
                    sizeof(epp));
                (void)read_cpu_field(cpus[cpu_slot], "scaling_min_freq", minimum, sizeof(minimum));
                (void)read_cpu_field(cpus[cpu_slot], "scaling_max_freq", maximum, sizeof(maximum));
                (void)fprintf(readback,
                    "cpu=%u\ngovernor=%s\nepp=%s\nmin=%s\nmax=%s\n",
                    cpus[cpu_slot],
                    governor,
                    epp,
                    minimum,
                    maximum);
            }
            (void)fclose(readback);
        }
        if (!requests_match) {
            fputs("status=stopped_policy_readback\n", stdout);
            exit_status = 3;
            goto restore;
        }
        {
            char precondition_path[512];
            FILE *precondition_file = NULL;
            uint64_t seen_khz[V4_HOLD_PRECONDITION_LIMIT];
            int ready = 0;
            if (snprintf(precondition_path,
                    sizeof(precondition_path),
                    "%s/precondition-samples.csv",
                    argv[2]) >= (int)sizeof(precondition_path)) {
                fputs("status=stopped_precondition\n", stdout);
                exit_status = 3;
                goto restore;
            }
            precondition_file = fopen(precondition_path, "w");
            if (precondition_file == NULL ||
                fputs("time_ns,frequency_khz\n", precondition_file) < 0) {
                if (precondition_file != NULL) {
                    (void)fclose(precondition_file);
                }
                fputs("status=stopped_precondition\n", stdout);
                exit_status = 3;
                goto restore;
            }
            while (precondition_count < V4_HOLD_PRECONDITION_LIMIT && !ready) {
                char frequency_text[64];
                struct timespec now;
                uint64_t frequency_khz = 0u;
                uint64_t time_ns = 0u;
                if (read_cpu_field(2u,
                        "scaling_cur_freq",
                        frequency_text,
                        sizeof(frequency_text)) != 0 ||
                    clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
                    break;
                }
                frequency_khz = strtoull(frequency_text, NULL, 10);
                time_ns = (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
                if (fprintf(precondition_file,
                        "%llu,%llu\n",
                        (unsigned long long)time_ns,
                        (unsigned long long)frequency_khz) < 0) {
                    break;
                }
                seen_khz[precondition_count] = frequency_khz;
                precondition_count += 1u;
                if (precondition_streak_ready(seen_khz,
                        precondition_count,
                        V4_HOLD_PRECONDITION_STREAK)) {
                    ready = 1;
                    break;
                }
                nanosleep(&(struct timespec){.tv_nsec = 20000000L}, NULL);
            }
            if (fclose(precondition_file) != 0) {
                fputs("status=stopped_precondition\n", stdout);
                exit_status = 3;
                goto restore;
            }
            if (!ready) {
                fputs("status=stopped_precondition\n", stdout);
                exit_status = 3;
                goto restore;
            }
        }
    }
    {
        char smt_path[512];
        if (snprintf(smt_path, sizeof(smt_path), "%s/smt-sibling-stat.txt", argv[2]) >=
            (int)sizeof(smt_path)) {
            goto restore;
        }
        smt_file = fopen(smt_path, "w");
        if (smt_file == NULL || copy_cpu_stat(smt_file, cpus[0], "start") != 0 ||
            copy_cpu_stat(smt_file, cpus[1], "start") != 0) {
            goto restore;
        }
        if (fclose(smt_file) != 0) {
            smt_file = NULL;
            goto restore;
        }
        smt_file = NULL;
    }
    child = fork();
    if (child < 0) {
        goto restore;
    }
    if (child == 0) {
        char *collector_argv[64];
        int collector_argc = 0;
        int separator = 0;
        for (int index = 3; index < argc && collector_argc < 63; ++index) {
            if (!separator) {
                if (strcmp(argv[index], "--") == 0) {
                    separator = 1;
                }
                continue;
            }
            collector_argv[collector_argc] = argv[index];
            collector_argc += 1;
        }
        collector_argv[collector_argc] = NULL;
        if (collector_argc == 0) {
            _exit(1);
        }
        execv(collector_argv[0], collector_argv);
        _exit(127);
    }
    child_started = 1;
    {
        char sample_path[512];
        char coverage_path[512];
        char smt_path[512];
        int running = 1;
        int child_reaped = 0;
        uint64_t frequencies[4096];
        uint64_t times[4096];
        size_t sample_count = 0u;
        double fraction = 0.0;
        int fraction_defined = 0;
        if (snprintf(sample_path, sizeof(sample_path), "%s/frequency-samples.csv", argv[2]) >=
            (int)sizeof(sample_path)) {
            running = 0;
        }
        sample_file = running ? fopen(sample_path, "w") : NULL;
        if (sample_file == NULL || fputs("time_ns,frequency_khz\n", sample_file) < 0) {
            running = 0;
        }
        while (running && sample_count < 4096u) {
            char frequency_text[64];
            char frequency_path[256];
            struct timespec now;
            pid_t waited = waitpid(child, &child_status, WNOHANG);
            if (waited == child) {
                child_reaped = 1;
            }
            if (cpu_frequency_path(2u,
                    "scaling_cur_freq",
                    frequency_path,
                    sizeof(frequency_path)) != 0 ||
                read_text(frequency_path, frequency_text, sizeof(frequency_text)) != 0 ||
                clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
                break;
            }
            frequencies[sample_count] = strtoull(frequency_text, NULL, 10);
            times[sample_count] =
                (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
            if (fprintf(sample_file,
                    "%llu,%llu\n",
                    (unsigned long long)times[sample_count],
                    (unsigned long long)frequencies[sample_count]) < 0) {
                break;
            }
            sample_count += 1u;
            if (child_reaped) {
                break;
            }
            nanosleep(&(struct timespec){.tv_nsec = 20000000L}, NULL);
        }
        if (running && sample_file != NULL && sample_count == 1u) {
            char frequency_text[64];
            char frequency_path[256];
            struct timespec now;
            if (cpu_frequency_path(2u,
                    "scaling_cur_freq",
                    frequency_path,
                    sizeof(frequency_path)) == 0 &&
                read_text(frequency_path, frequency_text, sizeof(frequency_text)) == 0 &&
                clock_gettime(CLOCK_MONOTONIC, &now) == 0) {
                frequencies[sample_count] = strtoull(frequency_text, NULL, 10);
                times[sample_count] =
                    (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
                if (fprintf(sample_file,
                        "%llu,%llu\n",
                        (unsigned long long)times[sample_count],
                        (unsigned long long)frequencies[sample_count]) >= 0) {
                    sample_count += 1u;
                }
            }
        }
        if (!child_reaped && waitpid(child, &child_status, 0) < 0) {
            child_status = 1;
        }
        if (sample_file != NULL) {
            (void)fclose(sample_file);
            sample_file = NULL;
        }
        if (snprintf(smt_path, sizeof(smt_path), "%s/smt-sibling-stat.txt", argv[2]) <
            (int)sizeof(smt_path)) {
            smt_file = fopen(smt_path, "a");
            if (smt_file != NULL) {
                (void)copy_cpu_stat(smt_file, cpus[0], "end");
                (void)copy_cpu_stat(smt_file, cpus[1], "end");
                (void)fclose(smt_file);
                smt_file = NULL;
            }
        }
        fraction_defined = v4_coverage_fraction(frequencies, times, sample_count, &fraction) == 0;
        if (snprintf(coverage_path, sizeof(coverage_path), "%s/coverage.txt", argv[2]) <
            (int)sizeof(coverage_path)) {
            FILE *coverage = fopen(coverage_path, "w");
            if (coverage != NULL) {
                if (fraction_defined) {
                    (void)fprintf(coverage, "coverage_fraction=%.17g\n", fraction);
                } else {
                    (void)fputs("coverage_fraction=na\n", coverage);
                }
                (void)fprintf(coverage,
                    "sample_count=%zu\nband_low_khz=%llu\nband_high_khz=%llu\n"
                    "sibling_cpu=%u\ncollector_status=%d\n",
                    sample_count,
                    (unsigned long long)V4_BAND_LOW_KHZ,
                    (unsigned long long)V4_BAND_HIGH_KHZ,
                    sibling,
                    WIFEXITED(child_status) ? WEXITSTATUS(child_status) : -1);
                if (hold_requested) {
                    (void)fprintf(coverage,
                        "hold_rule_id=%s\nprecondition_samples=%u\n",
                        V4_HOLD_RULE_ID,
                        precondition_count);
                }
                (void)fclose(coverage);
            }
        }
        if (WIFEXITED(child_status) && WEXITSTATUS(child_status) == 0 && fraction_defined) {
            exit_status = 0;
        } else if (WIFEXITED(child_status)) {
            exit_status = WEXITSTATUS(child_status) == 0 ? 1 : WEXITSTATUS(child_status);
        } else {
            exit_status = 1;
        }
    }
restore:
    if (sample_file != NULL) {
        (void)fclose(sample_file);
    }
    if (smt_file != NULL) {
        (void)fclose(smt_file);
    }
    if (frequency_requested) {
        int restored = 0;
        /* sysfs 接受写回后，紧接着的读可能仍是旧值。重试只核对基线，不改请求。 */
        for (int attempt_index = 0; attempt_index < 50 && !restored; ++attempt_index) {
            if (hold_requested) {
                for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
                    (void)write_cpu_field(cpus[cpu_slot],
                        "scaling_governor",
                        baseline_governor[cpu_slot]);
                    (void)write_cpu_field(cpus[cpu_slot],
                        "energy_performance_preference",
                        baseline_epp[cpu_slot]);
                }
            }
            for (int cpu_slot = 0; cpu_slot < 2; ++cpu_slot) {
                char path[256];
                if (cpu_frequency_path(cpus[cpu_slot], "scaling_min_freq", path, sizeof(path)) ==
                    0) {
                    (void)write_text(path, baseline_min[cpu_slot]);
                }
                if (cpu_frequency_path(cpus[cpu_slot], "scaling_max_freq", path, sizeof(path)) ==
                    0) {
                    (void)write_text(path, baseline_max[cpu_slot]);
                }
            }
            if (hold_requested) {
                (void)write_text(V4_BOOST_PATH, baseline_boost);
            }
            if (frequencies_match_baseline(cpus, baseline_min, baseline_max) == 0 &&
                (!hold_requested ||
                    hold_baseline_matches(cpus, baseline_governor, baseline_epp, baseline_boost) ==
                        0)) {
                restored = 1;
            } else {
                nanosleep(&(struct timespec){.tv_nsec = 20000000L}, NULL);
            }
        }
        /* 恢复失败不能报成功，否则后续会话会在被改过的频率请求上继续。 */
        if (!restored) {
            fputs("status=RESTORE_FAILED\n", stdout);
            return 4;
        }
    }
    if (child_started) {
        return exit_status;
    }
    return exit_status == 0 ? 1 : exit_status;
#endif
}
