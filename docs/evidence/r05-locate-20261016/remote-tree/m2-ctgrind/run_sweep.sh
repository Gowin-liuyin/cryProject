#!/bin/sh
set -u
ROOT=/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09
OUT="$ROOT/m2-ctgrind"
export TMPDIR="$ROOT/tmp" TMP="$ROOT/tmp" TEMP="$ROOT/tmp" XDG_CACHE_HOME="$ROOT/cache"
ZONES=8
for which in unfixed fixed; do
  for index in 0 1 2 3 4 5 6 7; do
    tag=$(printf "z%02dof%02d" "$((index+1))" "$ZONES")
    log="$OUT/logs/$which-$tag.log"
    taskset -c 0,1,3 valgrind --error-exitcode=99 --track-origins=yes \
      "$OUT/probe/probe_$which" "$ZONES" "$index" > "$log" 2>&1
    status=$?
    summary=$(grep -o "ERROR SUMMARY: [0-9]* errors from [0-9]* contexts" "$log" | tail -1)
    printf "%s %s zones=%s index=%s exit=%s %s\n" "$which" "$tag" "$ZONES" "$index" "$status" "$summary" >> "$OUT/run-log.txt"
  done
done
echo "SWEEP_DONE" >> "$OUT/run-log.txt"
