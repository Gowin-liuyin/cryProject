#define _POSIX_C_SOURCE 200809L

#include "protocol_decision.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static void write_row(FILE *file,
    const char *session_id,
    const char *category,
    unsigned elapsed,
    const char *hex_text)
{
    assert(fprintf(file,
               "session_decapsulation_v1,numeric-fixture,%s,0,k,0,none,%s,"
               "generate_test_ciphertext:%s,%u,CLOCK_MONOTONIC,%s\n",
               session_id,
               category,
               category,
               elapsed,
               hex_text) > 0);
}

static void test_numeric(const char *protocol_path, const char *analyzer_path)
{
    const char *temp_root = getenv("A113_TEST_TMPDIR");
    char csv_path[512];
    char command[2048];
    FILE *csv_file;
    struct frozen_protocol protocol;
    struct protocol_decision decision;
    struct session_effect effects[8];
    size_t session_count = 0u;
    double expected_p = 1.0 - 2.0 * atan(3.0) / acos(-1.0);
    int rejected[3] = {0};
    double p_values[3] = {0.001, 0.02, 0.03};
    int status;
    assert(temp_root != NULL && temp_root[0] == '/');
    assert(snprintf(csv_path, sizeof(csv_path), "%s/protocol-numeric.csv", temp_root) <
        (int)sizeof(csv_path));
    (void)remove(csv_path);
    csv_file = fopen(csv_path, "w");
    assert(csv_file != NULL);
    assert(fputs("schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,"
                 "category,generator_label,elapsed_clock_counts,clock_path,ciphertext_sha256_hex\n",
               csv_file) >= 0);
    write_row(csv_file,
        "s1",
        "message-zero",
        100u,
        "0000000000000000000000000000000000000000000000000000000000000000");
    write_row(csv_file,
        "s1",
        "message-zero",
        100u,
        "0000000000000000000000000000000000000000000000000000000000000000");
    write_row(csv_file,
        "s1",
        "message-ones",
        80u,
        "1111111111111111111111111111111111111111111111111111111111111111");
    write_row(csv_file,
        "s1",
        "message-ones",
        80u,
        "1111111111111111111111111111111111111111111111111111111111111111");
    write_row(csv_file,
        "s2",
        "message-zero",
        100u,
        "0000000000000000000000000000000000000000000000000000000000000000");
    write_row(csv_file,
        "s2",
        "message-zero",
        100u,
        "0000000000000000000000000000000000000000000000000000000000000000");
    write_row(csv_file,
        "s2",
        "message-ones",
        90u,
        "2222222222222222222222222222222222222222222222222222222222222222");
    write_row(csv_file,
        "s2",
        "message-ones",
        90u,
        "3333333333333333333333333333333333333333333333333333333333333333");
    write_row(csv_file,
        "s1",
        "valid",
        50u,
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    write_row(csv_file,
        "s1",
        "valid",
        50u,
        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
    write_row(csv_file,
        "s2",
        "valid",
        50u,
        "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc");
    write_row(csv_file,
        "s2",
        "valid",
        50u,
        "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");
    write_row(csv_file,
        "s1",
        "bit-flipped",
        50u,
        "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
    write_row(csv_file,
        "s1",
        "bit-flipped",
        50u,
        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    write_row(csv_file,
        "s2",
        "bit-flipped",
        50u,
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
    write_row(csv_file,
        "s2",
        "bit-flipped",
        50u,
        "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210");
    write_row(csv_file,
        "s1",
        "random",
        50u,
        "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff");
    write_row(csv_file,
        "s1",
        "random",
        50u,
        "ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100");
    write_row(csv_file,
        "s2",
        "random",
        50u,
        "0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0");
    write_row(csv_file,
        "s2",
        "random",
        50u,
        "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef");
    assert(fclose(csv_file) == 0);
    assert(protocol_load(protocol_path, &protocol) == 0);
    assert(protocol_decide(&protocol,
               csv_path,
               "numeric",
               1u,
               &decision,
               effects,
               8u,
               &session_count) == 0);
    assert(fabs(decision.primary_mean_difference_counts - 15.0) < 1e-9);
    assert(fabs(decision.primary_t_statistic - 3.0) < 1e-9);
    assert(fabs(decision.primary_p_value - expected_p) < 1e-6);
    assert(decision.holm_rejected_primary == 0);
    assert(strcmp(decision.iid_upgrade, "refused") == 0);
    assert(strcmp(decision.constant_time_upgrade, "refused") == 0);
    assert(strcmp(decision.thresholds_chosen_after_data, "no") == 0);
    assert(fabs(protocol_student_t_two_sided(3.0, 1u) - expected_p) < 1e-9);
    protocol_holm(p_values, 3u, 0.01, rejected);
    assert(rejected[0] == 1);
    assert(rejected[1] == 0);
    assert(rejected[2] == 0);
    assert(snprintf(command,
               sizeof(command),
               "'%s' --phase numeric --protocol '%s' --csv '%s' --seed 1",
               analyzer_path,
               protocol_path,
               csv_path) < (int)sizeof(command));
    status = system(command);
    assert(status == 0);
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        return 1;
    }
    test_numeric(argv[1], argv[2]);
    return 0;
}
