#!/bin/sh
set -eu
class_directory=$1
upstream_directory=$2
temporary_root=$3
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
mkdir -p -- "${temporary_root}"
work_directory=$(mktemp -d "${temporary_root}/platform-mona.XXXXXX")

awk 'BEGIN {print "class0_ns,class1_ns"; for (row_index=0; row_index<1000; row_index++) {value=10000+row_index%100; print value "," value}}' > "${work_directory}/equal.csv"
awk 'BEGIN {print "class0_ns,class1_ns"; for (row_index=0; row_index<1000; row_index++) {value=10000+row_index%100; print value "," value+1000000}}' > "${work_directory}/shifted.csv"
for dataset_name in equal shifted; do
    sh "${script_directory}/run.sh" --input "${work_directory}/${dataset_name}.csv" \
        --output-dir "${work_directory}/${dataset_name}" --class-dir "${class_directory}" \
        --upstream-dir "${upstream_directory}"
done
grep -q '"status": "no_validated_box_separation"' "${work_directory}/equal/mona.json"
grep -q '"status": "validated_box_separation"' "${work_directory}/shifted/mona.json"
awk -F, 'NR == 1 {print "V1,V2"; next} {print "X," $1; print "Y," $2}' \
    "${work_directory}/shifted.csv" > "${work_directory}/normalized.csv"
sh "${script_directory}/run.sh" --input "${work_directory}/normalized.csv" \
    --output-dir "${work_directory}/normalized" --class-dir "${class_directory}" \
    --upstream-dir "${upstream_directory}"
cmp "${work_directory}/shifted/mona.csv" "${work_directory}/normalized/mona.csv"
printf 'class0_ns,class1_ns\n1,2,3\n' > "${work_directory}/malformed.csv"
if sh "${script_directory}/run.sh" --input "${work_directory}/malformed.csv" \
    --output-dir "${work_directory}/malformed" --class-dir "${class_directory}" \
    --upstream-dir "${upstream_directory}"; then
    printf '%s\n' 'Malformed CSV was accepted.' >&2
    exit 1
fi
if sh "${script_directory}/run.sh" --input "${work_directory}/equal.csv" \
    --output-dir "${work_directory}/equal" --class-dir "${class_directory}" \
    --upstream-dir "${upstream_directory}"; then
    printf '%s\n' 'Existing output directory was accepted.' >&2
    exit 1
fi
printf 'mona_calibration_passed=%s\n' "${work_directory}"
