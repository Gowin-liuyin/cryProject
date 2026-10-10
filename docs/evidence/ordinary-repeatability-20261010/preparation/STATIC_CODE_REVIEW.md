# Ordinary reference repeatability: bounded static review

What this change does: It measures the complete existing ML-KEM-768 reference wrapper on one fixed public NIST input. It saves two raw clock reads and the public output check for each call, then describes each process separately.

**Looks good within this static scope. No must-fix or should-fix finding was found. Proceed to the required software qualification.** This reviewer did not implement the collector, analyzer or CMake module. This is a same-model internal independent review, not external peer review; external Codex MCP review is unavailable and remains `[pending Codex review]`.

## Checked source and input

All five requested module files were read. The existing wrapper, erase routine, baseline configuration, NIST test entry points, fixture JSON, converted vector, and relevant fixed rejection-output source were also checked. Source hashes are bound in `STATIC_CODE_REVIEW.json`; this review does not assign an uncommitted source snapshot a Git commit.

The three header arrays match NIST `tgId=5,tcId=86` and the converted vector byte for byte: decapsulation key 2400 bytes, ciphertext 1088 bytes, expected value 32 bytes. Their hashes match the contract. The VAL group alone does not identify an accepted ciphertext. A one-off external SHAKE256 calculation on the public bytes independently reproduces the recorded inequality between expected output and `J(z||c)`, with rejection-value SHA256 `77e3410e3d8a9f969d59200acd8064921c8003817a3f8481fb95dc059bfd48a3`. This ran no full decapsulation and is not a runtime classifier. The contract correctly still requires the new reference fixture check to return the published expected output before claiming this sample is valid.

The clock structure and five clock helper bodies match fixed G2 source `c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2` exactly, including source SHA256 `520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0`. Seven statistic/geometry helper bodies match the prior RAW analyzer exactly. Reuse of source does not certify a new binary or an old run.

## Collector control flow

- `prepare_collection` first sets and reads back process dumpability on Linux, then checks the reference identity and records machine/affinity state. Allocation and page touching happen before sampling. Only the caller's CPU2 affinity is set; no root, MSR, frequency, partition or IRQ work is added.
- Each timed call uses first raw timespec read, success check, compiler fence, complete `mlkem_decapsulate` wrapper, compiler fence, second raw timespec read. Both conversions and order checks occur afterward in source. The full 32-byte comparison, volatile result consumption, volatile erase and attempt/valid counters are outside the measured window. The output buffer is initialized before the first read.
- A failed first read leaves operation unperformed with null operation status/output match. A failed second read still records that the full call happened, including its status and public match where known. Operation errors remain separate from clock errno; a nonzero operation return is not copied into the clock fields.
- The final row is safe: completion depends on exactly 25000 valid warmup and 25000 valid main calls, not merely `record_count==50000`. A last-row clock/output/operation failure cannot promote the process to completed. An after-environment failure can change completed to failure.
- The setup fixture call is separate and occurs at most once. The loop permits at most 50000 timed calls, so a fully completed collector has 50001 direct full calls. A killed process may lose in-memory observations; its actual count then stays unknown as the contract states.
- CSV formatting retains 18 fields, null values and signed operation errors. stdout write/flush/close and metadata write/flush/close failures prevent exit zero. No key, shared value, sink value or internal acceptance flag is printed. The source calls the existing volatile erase routine after every performed timed call and after setup.
- On macOS the collect branch is unsupported and runs no algorithm. The collector's pure selfcheck contains no crypto, real clock or affinity call. The fixture check deliberately performs one full call; the Linux process-safety check performs zero crypto calls.

## Analyzer and build

The parser requires the exact 18-column header, 50000 rows, continuous index, first/last 25000 phase split, exact successful operation literals, both raw clock success states, checked conversion, elapsed difference and nondecreasing original order. Embedded NUL, missing LF, extra/short fields, null failures, wrong operation status/output and trailing records are rejected. It validates all input and all formatted results before publishing any success table; it does not salvage a successful prefix.

Each phase emits counts 25000/24999/49999 for within/between/combined increments. Zero values and long tails are retained. Fixed percentile index, upper-median MAD, checked sums, within-phase and cross-phase conservation follow the unchanged RAW functions. The two 49999-element work arrays and 50000 compact pairs have 1599984 bytes of explicit array storage; bounded format/input/statistic buffers are covered by the compile-time less-than-16-MiB assertion. This is not a process RSS limit. The collector's separate allocation has a compile-time SIZE_MAX fit check.

The analyzer leaves metadata/exit/precision/iid/acceptance flags false; complete metadata acceptance remains the manager's job. Successful CSV parsing cannot establish input provenance, binary identity, valid runtime environment or a scientific assumption by itself.

CMake links the original kernel, wrapper and random/erase source under the 768 baseline configuration. No variant macro or patch is added. IPO is false on all concrete targets; actual compiler/link flags and ordinary machine code still require qualification review. Ordinary and ASan/UBSan builds are separate. CTest registers four entries on macOS, adding only the process-safety entry on Linux for five, and never registers collect as a test.

The existing KAT path has 25 keygen, 25 encapsulation and 10 decapsulation cases plus 20 key checks. The public-boundary preparation and random round trip bring one KAT entry to 27/27/11 full calls, plus 18 wrapper argument rejects and 10 public SHAKE references. The separate fixture adds one decapsulation. The contract's 132 full calls across two configurations and planned Linux totals 300138 full calls/300030 decapsulations are consistent with this direct-entry count.

## Limits and routing

This review does not execute C, CMake, tests, SSH, a collector or any full cryptographic operation. The external public-byte SHAKE reference and byte/function comparisons are offline review aids. It does not certify compiled ordering, the actual libc/vDSO path, failure-path runtime behavior, timing precision, independence, stationarity, resource isolation, frequency constancy or R02/R04 acceptance. The complete future manager and its remote path/lifecycle behavior are outside these five files and need their own review.

The corrected contract distinguishes six data sets and two nearby connection batches, without treating a reconnect as an independent machine state. Software qualification must pass on the final fixed source, followed by actual ordinary ELF/fixture/metadata checks before sampling. Any meaningful code change requires review of its delta; this report binds only the byte hashes recorded beside it.

Verdict: Ship.

Not checked: actual compilation, execution, sanitizer results, ELF ordering/linkage, remote management and hardware data; all remain pending their own evidence.
