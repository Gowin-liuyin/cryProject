#ifndef BASELINE_V4_REDUCE_H
#define BASELINE_V4_REDUCE_H

#include <stddef.h>

/* 从采集目录重算会话效应。stop_status 非空时不产生可确认的效应。 */
int v4_reduce_manifest(const char *manifest_path,
    int require_binary_digest,
    int require_coverage,
    double *effects,
    double *empty_medians,
    double *coverages,
    size_t capacity,
    size_t *session_count,
    const char **stop_status);

#endif
