#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
    printf '%s\n' 'usage: run_m1.sh REPOSITORY_ROOT MONA_CLASS_DIRECTORY NEW_OUTPUT_DIRECTORY' >&2
    exit 2
fi
repository_root=$(CDPATH= cd -- "$1" && pwd -P)
class_directory=$(CDPATH= cd -- "$2" && pwd -P)
output_directory=$3
if [ -e "${output_directory}" ] || [ -L "${output_directory}" ]; then
    printf '%s\n' 'Output directory must not exist.' >&2
    exit 2
fi
mkdir -p -- "$(dirname -- "${output_directory}")"
mkdir -- "${output_directory}"
output_directory=$(CDPATH= cd -- "${output_directory}" && pwd -P)
printf 'dataset,tool,status,class0_count,class1_count,validated_records,rejected_records,holm_member\n' \
    > "${output_directory}/m1-mona.csv"
while IFS='|' read -r dataset_name csv_relative_path; do
    sh "${repository_root}/scripts/platform_mona/run.sh" \
        --input "${repository_root}/${csv_relative_path}" \
        --output-dir "${output_directory}/${dataset_name}" --class-dir "${class_directory}" \
        --upstream-dir "${repository_root}/third_party/mona-timing-report"
    awk -v dataset_name="${dataset_name}" 'NR>1 {print dataset_name "," $0}' \
        "${output_directory}/${dataset_name}/mona.csv" >> "${output_directory}/m1-mona.csv"
done <<'DATASETS'
primary-vulnerable|docs/evidence/tooling-strengthen-20261015/csv/vulnerable-message-zero-ones.csv
primary-fixed|docs/evidence/tooling-strengthen-20261015/csv/fixed-message-zero-ones.csv
seed-424242-vulnerable|docs/evidence/r02-r04-close-20261016/raw/seed-424242/csv/vulnerable-message-zero-ones.csv
seed-424242-fixed|docs/evidence/r02-r04-close-20261016/raw/seed-424242/csv/fixed-message-zero-ones.csv
cpu-6-vulnerable|docs/evidence/r02-r04-close-20261016/raw/cpu-6/csv/vulnerable-message-zero-ones.csv
cpu-6-fixed|docs/evidence/r02-r04-close-20261016/raw/cpu-6/csv/fixed-message-zero-ones.csv
DATASETS
