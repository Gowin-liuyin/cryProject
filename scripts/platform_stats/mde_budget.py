#!/usr/bin/env python3
"""MDE（最小可检出效应）预算工具：pilot 预研估算，不作正式统计出口。

输入 pilot CSV（两列宽表）：
    class_zero_nanoseconds,class_ones_nanoseconds
    每行一组 pilot 观测（两类不要求配对）；至少每类 2 个样本。

冻结公式（写死，不从命令行改）：
    σ_pooled² = ((n0-1)·s0² + (n1-1)·s1²) / (n0+n1-2)
    n_per_class = 2·(z_{1-α/2} + z_{power})² · σ_pooled² / Δ²
    α = 0.05（双侧）、power = 0.8，z_{0.975}=1.959963984540054、
    z_{0.800}=0.8416212335729143，故 2·(z 和)² = 15.697759468698177。
输出向上取整的每类样本量（最少 2）。

边界声明（必须随输出）：pilot 预研估算，不作正式统计出口；正式统计仍由 C 件
（platform_holm / platform_shape_stats）承担。本工具不执行采集、不写任何证据目录。
"""

import argparse
import math
import sys

ALPHA = 0.05
POWER = 0.8
Z_ALPHA_TWO_SIDED = 1.959963984540054
Z_POWER = 0.8416212335729143
TWO_GROUP_FACTOR = 2.0 * (Z_ALPHA_TWO_SIDED + Z_POWER) ** 2
MINIMUM_SAMPLES_PER_CLASS = 2
BOUNDARY_STATEMENT = (
    "pilot 预研估算，不作正式统计出口；正式统计仍由 C 件"
    "（platform_holm / platform_shape_stats）承担。"
)
CSV_HEADER = ("class_zero_nanoseconds", "class_ones_nanoseconds")


class MdeBudgetError(Exception):
    pass


def parse_nanoseconds(text):
    value = float(text)
    if not math.isfinite(value):
        raise MdeBudgetError("non-finite nanosecond value: %r" % text)
    return value


def load_pilot_csv(path):
    class_zero_samples = []
    class_ones_samples = []
    with open(path, "r", encoding="utf-8", newline="") as input_file:
        header_line = input_file.readline()
        header_fields = [field.strip() for field in header_line.strip().split(",")]
        if tuple(header_fields) != CSV_HEADER:
            raise MdeBudgetError(
                "unexpected CSV header %r (expected %r)" % (header_fields, list(CSV_HEADER))
            )
        for line_number, line in enumerate(input_file, start=2):
            if line.strip() == "":
                continue
            fields = line.strip().split(",")
            if len(fields) != 2:
                raise MdeBudgetError("line %d has %d fields, expected 2" % (line_number, len(fields)))
            class_zero_samples.append(parse_nanoseconds(fields[0]))
            class_ones_samples.append(parse_nanoseconds(fields[1]))
    if len(class_zero_samples) < MINIMUM_SAMPLES_PER_CLASS:
        raise MdeBudgetError("pilot CSV needs at least %d rows" % MINIMUM_SAMPLES_PER_CLASS)
    return class_zero_samples, class_ones_samples


def sample_variance(samples):
    mean = sum(samples) / float(len(samples))
    square_sum = sum((value - mean) ** 2 for value in samples)
    return square_sum / float(len(samples) - 1)


def pooled_standard_deviation(class_zero_samples, class_ones_samples):
    zero_count = len(class_zero_samples)
    ones_count = len(class_ones_samples)
    zero_variance = sample_variance(class_zero_samples)
    ones_variance = sample_variance(class_ones_samples)
    degrees_of_freedom = zero_count + ones_count - 2
    pooled_variance = (
        (zero_count - 1) * zero_variance + (ones_count - 1) * ones_variance
    ) / float(degrees_of_freedom)
    if pooled_variance <= 0.0:
        raise MdeBudgetError("pooled variance is zero; MDE is not defined")
    return math.sqrt(pooled_variance), degrees_of_freedom


def required_samples_per_class(pooled_sd_nanoseconds, delta_nanoseconds):
    if delta_nanoseconds <= 0.0:
        raise MdeBudgetError("delta must be positive")
    requirement = TWO_GROUP_FACTOR * (pooled_sd_nanoseconds**2) / (delta_nanoseconds**2)
    return max(MINIMUM_SAMPLES_PER_CLASS, int(math.ceil(requirement)))


def build_argument_parser():
    parser = argparse.ArgumentParser(
        description="MDE pilot estimate (fixed alpha=0.05 two-sided, power=0.8)"
    )
    parser.add_argument("--input", required=True, help="pilot CSV (two columns of nanoseconds)")
    parser.add_argument("--delta-nanoseconds", required=True, help="target detectable delta M (ns)")
    parser.add_argument("--output", default=None, help="optional output text file")
    return parser


def main(argument_values=None):
    parser = build_argument_parser()
    arguments = parser.parse_args(argument_values)
    try:
        delta_nanoseconds = float(arguments.delta_nanoseconds)
        class_zero_samples, class_ones_samples = load_pilot_csv(arguments.input)
        pooled_sd_nanoseconds, degrees_of_freedom = pooled_standard_deviation(
            class_zero_samples, class_ones_samples
        )
        samples_per_class = required_samples_per_class(pooled_sd_nanoseconds, delta_nanoseconds)
    except (OSError, ValueError, MdeBudgetError) as error:
        print("mde_budget error: %s" % error, file=sys.stderr)
        return 2
    lines = [
        "mde_budget: alpha=%.2f (two-sided) power=%.1f factor=%.15g" % (
            ALPHA,
            POWER,
            TWO_GROUP_FACTOR,
        ),
        "input_path=%s" % arguments.input,
        "rows_class_zero=%d rows_class_ones=%d degrees_of_freedom=%d"
        % (len(class_zero_samples), len(class_ones_samples), degrees_of_freedom),
        "pooled_standard_deviation_nanoseconds=%.15g" % pooled_sd_nanoseconds,
        "delta_nanoseconds=%.15g" % delta_nanoseconds,
        "required_samples_per_class=%d" % samples_per_class,
        "boundary=%s" % BOUNDARY_STATEMENT,
    ]
    text = "\n".join(lines) + "\n"
    if arguments.output is not None:
        try:
            with open(arguments.output, "w", encoding="utf-8") as output_file:
                output_file.write(text)
        except OSError as error:
            print("mde_budget error: cannot write %s: %s" % (arguments.output, error), file=sys.stderr)
            return 2
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
