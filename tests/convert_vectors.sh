#!/bin/sh
set -eu
cd "$(dirname "$0")/vectors"
jq -nr --slurpfile prompts keygen-prompt.json --slurpfile answers keygen-expected.json '
  $prompts[0].testGroups[] | select(.parameterSet == "ML-KEM-768") | .tests[] as $test |
  $answers[0].testGroups[].tests[] | select(.tcId == $test.tcId) |
  ["keygen", $test.tcId, ($test.d + $test.z), .ek, .dk] | @tsv' > mlkem768.txt
jq -nr --slurpfile prompts encdec-prompt.json --slurpfile answers encdec-expected.json '
  $prompts[0].testGroups[] | select(.parameterSet == "ML-KEM-768") |
  .function as $operation | .tests[] as $test |
  $answers[0].testGroups[].tests[] | select(.tcId == $test.tcId) |
  if $operation == "encapsulation" then ["encap", $test.tcId, $test.ek, $test.m, .c, .k]
  elif $operation == "decapsulation" then ["decap", $test.tcId, $test.dk, $test.c, .k]
  else empty end | @tsv' >> mlkem768.txt
