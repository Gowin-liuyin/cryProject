# Independent RAW-clock source review — round 1

Date: 2026-10-10. Reviewer: independent agent `raw_clock_design_review`.
Scope: static inspection of the five files below, the fixed G2 collector source at `c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2`, and the existing G2 timing-description contract/results. No compilation, CTest, collector execution, SSH, hardware reads, edits to production sources, or changes to sealed evidence were performed. This is a same-model independent source review, not external Codex or cross-model review.

What this change does: A C11 collector records a fixed sequence of empty RAW-clock pairs without linking cryptography or modifying global resource settings. A separate C11 analyzer accepts only a complete, internally consistent 101000-row CSV and emits six descriptive rows plus integer time-accounting checks. The analyzer explicitly does not accept collector metadata or exit status on the operator's behalf.

## Reviewed bytes

| File | SHA-256 |
|---|---|
| `raw_clock_calibration.c` | `841ccb0f485def007e8539eeccdbf762315cbbfacc6ea6e406534e03f81d41ca` |
| `analyze_raw_clock.c` | `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0` |
| `CMakeLists.txt` | `7b3629d8cf994daeaf6a49509640f0aa1954129c0497caabe424a97dffb7a529` |
| `README.md` | `88e18d55daea075a16a09129a888e41a24c9b561f76784d9789a0055d6710f0a` |
| `ANALYSIS_CONTRACT.md` | `693ac31279a88c5c89fde29995979ea1291e5c0fc346d1776874f73742501ce4` |

The module was untracked during this review. Final source qualification must bind the final integrated versions, not the earlier collector-only Mac builds.

## Must fix

1. **The collector does not check closing its metadata stream** (`raw_clock_calibration.c`, `output_metadata` and `run_collection`, lines 539–652 in the reviewed bytes).

   What this is: stdout CSV is explicitly flushed, closed, and checked before metadata is published. stderr JSON is flushed and checked, but never explicitly closed before the return code is selected.

   Problem: README promises that output close failures return 1. A failure reported only while stderr is closed by exit cleanup cannot change the current success return. In particular, this differs from the explicit close-error handling already implemented for stdout; complete stream-output success is stronger than successful buffered writes and flushes alone.

   Fix: After `output_metadata`, explicitly close stderr and combine the close result with `metadata_ok` when selecting the exit code. Once the stream is closed no additional diagnostic needs to be written there; the external run receipt must treat any nonzero status as unknown. Alternatively, narrow the documentation to the exact close checks actually implemented, although explicit closure better matches the declared receipt contract.

   If skipped: A close-time metadata error may still be accompanied by collector exit 0, contrary to the documented acceptance conditions.

## Checked and consistent

- `struct clock_reading` and all five named helper function blocks are byte-identical to the corresponding blocks extracted read-only from the fixed G2 source. The comparison was made against `git show c0e5990...`, not an inferred implementation. Helper block SHA-256 values are listed below.
- `record_empty_pair` preserves the relevant G2 ordering: first `read_clock_timespec`, successful-read branch, two adjacent `atomic_signal_fence(memory_order_seq_cst)` calls with no tested function between them, second `read_clock_timespec`, then both conversions and order checks. It does not substitute two calls to the heavier `read_clock`. Attempt bookkeeping before the first read and after the second read is outside the observed pair interior. Adjacent signal fences may generate no hardware instruction, which README correctly states.
- Each attempted pair consumes one record slot before reading; valid warmup and main counters advance only after both readings validate. A first-read failure leaves `after_attempted=false`; a second-read failure remains attempted with its own error. Failed conversions preserve original timespec fields. Reversed values remain in the record with ERANGE. Valid equal timestamps remain valid zero increments.
- Records are allocated once before collection; volatile writes touch each allocated page and the final byte before warmup. Allocation-size multiplication is statically bounded. The collection loop adds no allocation, I/O, affinity query or budget clock inside sampling.
- Early environment failures are reported with unavailable snapshots/fields as null rather than fabricated successful zeros. Before/after metadata is captured outside the sampling loop. Successful collection counts alone do not override a later environment or stdout failure. The first failure reason is preserved when more than one operation fails.
- The only resource-setting API is `sched_setaffinity(0, ...)` for the current thread. Before/after CPU2 checks do not assert exclusive reservation or continuous CPU service. No MSR, crypto, sleep, global frequency or cgroup write is present in the inspected collector.
- The analyzer checks the exact 15-column header, LF termination, embedded NUL, field count, every index and phase, complete fixed row count, clean EOF, read/close errors, successful attempted clocks, unsigned numeric syntax, timespec conversion, and per-record/cross-record ordering. Trailing CR, whitespace, null, extra rows, incomplete rows and failed records are rejected. No invalid surviving subset is summarized.
- Decimal parsing checks each multiplication/addition before overflow. Timespec conversion checks both seconds multiplication and fractional addition. All subtraction occurs only after order checks. Array indices stay within 101000 records and 199999 increment/deviation slots; phase pointers and result offsets cover exactly six result rows. In-place heap sorting and fixed percentile indices are consistent with the declared formula.
- Within-pair, between-pair and combined increments preserve zeros and tails and use the declared counts. All sums are checked; each phase conserves its wall-clock span. The warmup/main boundary gap is checked separately and is not inserted into either phase series. P50 and MAD use the declared upper median, and no-positive-value is null.
- All parsing, statistics and formatting finish before analyzer output is published. The analyzer's successful JSON expressly retains `collector_stderr_checked=false`, `collector_exit_checked=false`, and `complete_metadata_acceptance=false`; complete CSV therefore cannot impersonate complete collector-run acceptance. Output write/flush faults and process termination still require external unknown-state handling.
- README explicitly limits the result to this new empty-window executable, rather than retroactively proving G2 machine code, vDSO/syscall dispatch, absolute error, constant frequency or per-call overhead correction. The fixed 1000-pair warmup is not claimed equivalent to G2's one-second warmup. Source-level similarity is not binary equivalence.

## Fixed-source block comparison

| G2 block | Byte-equal | SHA-256 of extracted block |
|---|---|---|
| `struct clock_reading` | yes | `7c74e251393497967aec95022f7307551c40549263e292edb162ee306633b068` |
| `timespec_to_nanoseconds` | yes | `4f623b855ce89fe912f99c76c927dc748f8ddcf9cf4c419e929e6f0554845d84` |
| `clock_span_is_valid` | yes | `d7613c8015ff586798752a259528ce4dd078fecdc90187acaa96938ef4f5363e` |
| `check_clock_order` | yes | `265ab1918ee1966d2e78760689ee5822d300db2932cee6952070d2cda49c7822` |
| `read_clock_timespec` | yes | `f3d050c5e5ac00650e72278341d90ae1f17e08ec88e38ed437a420160f159117` |
| `convert_clock_reading` | yes | `050c3e5e2dad7b32125f0196c3cd604d732d66e04dd90d91c93f2b2ed17ca719` |

## Pending integration and execution

At the inspected hashes, CMake still contains one executable and one selfcheck. Parent agent has identified this as unfinished integration and is adding the analyzer target, matching ordinary/dynamic options, both CTest registrations, both files in format-check, and an EXPERIMENT_PLAN. This is not evidence that the analyzer is already registered or tested. README's one-target statement must be updated with that integration.

The three-fixed-process protocol is not implemented by these two tools and must be frozen and enforced externally: exactly three new processes in fixed order, each at most once, bounded lifecycle including output, no result-dependent replacement, private Cry paths for every project output/cache/temp, and a receipt that binds exit status, CSV, metadata, source and ordinary ELF. Three nearby processes support only a finite recent descriptive comparison, not cross-session stability, iid, or full-workload process repeatability. Current final integrated software qualification and Linux calibration remain unexecuted from this reviewer's perspective.

Verdict: fix 1 and complete the declared integration before final source qualification. No additional numeric, indexing or G2-helper-order blocker was identified in the inspected bytes.

Not checked: Compilation/CTest, compiler-emitted machine code, actual stream fault injection, real Linux environment, authentication, SSH, actual collection, physical clock precision, and the not-yet-present final experiment plan were not executed or certified here.


# Narrow follow-up — round 2

Date: 2026-10-10. The same independent reviewer read the collector close delta, integrated CMake, revised README, and the new complete experiment plan. No compilation, CTest, collection, SSH, or hardware access was performed. This follow-up does not repeat or silently replace round 1.

| File | SHA-256 |
|---|---|
| `raw_clock_calibration.c` | `ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd` |
| `analyze_raw_clock.c` | `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0` |
| `CMakeLists.txt` | `657755b80e4d636acafb2740a7ca29ca13fc99de7c8b1a9840c396b45fac7183` |
| `README.md` | `767ce355b34a14a62d04ad5a5042059c84e7b1f7fd9220f8d828ce8967059021` |
| `ANALYSIS_CONTRACT.md` | `693ac31279a88c5c89fde29995979ea1291e5c0fc346d1776874f73742501ce4` |
| `EXPERIMENT_PLAN.md` | `c3ed62a2df52705825ca673ea3c865e81b528d17ecf2efbe6547c0fd0d101974` |

## Issue 1 is closed

`run_collection` now calls `fclose(stderr)` after `output_metadata` and sets `metadata_ok=false` if closure fails. The return requires `records_ok && metadata_ok && completed`, so a metadata-stream close failure cannot return success. Removing exactly this three-line block from the new collector reconstructs the full round-1 SHA-256 `841ccb0f485def007e8539eeccdbf762315cbbfacc6ea6e406534e03f81d41ca`. The inspected collector change is therefore limited to the requested stream-close correction; no previously reviewed sampling/helper code changed.

## Build integration is complete at source level

CMake now declares both executables, applies the same C11/strict-warning/no-LTO and optional sanitizer settings to both, registers both selfchecks with CTest, and includes both C files in format-check. The formatter-version regex is `version 21[.]`. README now accurately states two targets and identifies the second selfcheck. This proves source registration only; final ordinary/dynamic execution remains the parent's separate qualification step. The earlier collector-only checks are explicitly preserved as development history and cannot qualify the integrated final source.

## Experiment-plan boundary review

The new plan freezes three new ordinary-user processes, P1/P2/P3 in fixed order, each attempted at most once, 1000 warmup and 100000 main pairs per process. It separates 606000 planned sampling clock reads from other management/metadata reads, and preserves tails and failures without adaptive replacements. Each collector receives a 10-second external deadline and a further 2-second forced-stop/reap allowance, including output; the whole remote stage is capped at 300 seconds with stated disk/output limits. Those are external management duties, not claims that the C loop is hard real time.

The plan keeps all project paths, caches, temporary files and archives in the physical Cry subtree; calls for ordinary/dynamic Linux qualification separately; and excludes root, MSR, crypto and global resource writes. Self CPU2 affinity does not become a reservation or G2-equivalent frequency/isolation condition. Original CSV validation and collector exit/metadata acceptance remain distinct. Three nearby empty-window processes remain descriptive rather than independent/cross-session/full-decap repeats; R02/R04 stay partial regardless of how close their summaries appear. The plan's earlier preflight assertion was read as a plan statement, not independently re-executed or certified by this reviewer.

## One plan-wording correction remains before collection

The experiment plan currently calls its percentiles “最近秩P50/P90/P99”, while the unchanged analyzer and ANALYSIS_CONTRACT specify the fixed position index `((n-1)*P+50)/100`. That differs from the common nearest-rank definition `ceil(n*P/100)-1`: at the actual warmup between-pair count n=999, P90 is index 898 under this implementation and index 899 under nearest rank. Replace the plan phrase with an explicit reference to the fixed analysis-contract index. No numerical implementation, sample count or metric change is requested. The parent was notified before collection.

Verdict: The I/O blocker is closed and both-target integration is coherent at source level. Correct the isolated percentile-method label before freezing collection; final software qualification and real collection are not certified by this review.


# Final terminology and hash confirmation — round 3

Date: 2026-10-10. Narrow read-only confirmation; no tests, compilation, SSH, hardware reads or collection.

The frozen EXPERIMENT_PLAN SHA-256 is now `7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a`. The isolated phrase is now “按分析合同固定位置索引的P50/P90/P99”. Replacing exactly that one phrase with its previous “最近秩P50/P90/P99” reconstructs the complete preceding plan SHA-256 `c3ed62a2df52705825ca673ea3c865e81b528d17ecf2efbe6547c0fd0d101974`. Hence this correction changes terminology only; CPU, counts, order, budget, lifecycle and claim scope remain the already reviewed plan bytes.

All five code/build/document SHA-256 values in round 2 were rechecked and remain unchanged. The numerical percentile definition and analyzer code are unchanged. The terminology finding is resolved.

The parent reports that a software agent stopped on the old plan hash before any build and is using a new directory for final unified qualification. This reviewer has not inspected or rerun those process records, and does not count that attempted preparation as completed software qualification. No real collection is certified by this review.

Final source-review verdict: No outstanding blocker in the reviewed collector/analyzer, integrated build registration, documentation or frozen experiment-plan boundary. The stderr-close finding and percentile-method terminology finding are both closed. Final ordinary/dynamic software execution and real Linux run acceptance remain separate evidence obligations. This source-level verdict does not certify physical clock precision, iid, full-workload repeatability, R02 or R04.
