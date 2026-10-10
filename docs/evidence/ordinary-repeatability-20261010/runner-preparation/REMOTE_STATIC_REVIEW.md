# Ordinary repeatability manager: initial independent static review

What this change does: It runs one of two fixed Linux connection batches. E1 qualifies the fixed programs and runs three ordinary collectors; E2 checks the frozen E1 tree and reuses the same six binaries, then saves a new manifest and archive.

**Verdict: fix 1 and 2 first. Do not deploy this reviewed version.** This is a same-model internal independent bounded review. The reviewer did not implement the manager. External Codex MCP is unavailable and remains `[pending Codex review]`.

Reviewed runner SHA256: `40b74f05bf8ec9d29e80d5788a9c7fe447c771bdd35c97c542c3abd649088938`. Source-manifest SHA256: `c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552`. Remote-contract SHA256: `ccb0ec975d52bcbfda5acec69784cdde6604b9114533976d37c284d1fe315fc2`. Frozen plan SHA256: `90ced1f1d1157f80997f5af3e2afaeb83c7bf8a488c00c229ac77d55d7cd70ec`. The exact reviewed Python source is preserved in build as `remote_run-reviewed-initial.py`; this page is not silently updated to a later repair.

## Must fix

1. **A losing batch-directory claim can write into the winning run** (`remote_run.py:589`, `:654`, `:676`).
   - **What this is:** Early existence checks are followed later by exclusive `batch_root.mkdir`. The common finally block always performs export work, even if that mkdir never succeeded.
   - **Problem:** Start two invocations for the same new ROOT/batch. Both can pass the early existence checks before either creates the batch. The loser gets FileExistsError at mkdir, but its empty command list makes `export_is_safe` true. It can then exclusively create the winner's not-yet-written after-environment, commands, run-state and manifest files, and even archive the winner's active tree. No overwrite is needed for this failure.
   - **Fix:** Record ownership only after successful exclusive batch creation. A failed claim must not run any batch-path finalization or archive creation. Return a separate stdout failure receipt. Also make the ownership transition safe against handled signals so a successfully created directory does not lose its owner flag.
   - **If we skip it:** A duplicate launch can prevent the legitimate run from saving its final evidence, while producing a failed snapshot of a still-running tree. The no-retry rule then makes the actual sampling evidence difficult to recover.

2. **Freeze replaces accepted input pins instead of checking them** (`remote_run.py:688`–`:692`, plus accepted analysis pins at `:644`–`:646`).
   - **What this is:** Acceptance stores SHA values after C analysis and checks the collector originals. During export, the code assigns current CSV/metadata SHA values into the same case fields again. It does not recheck accepted analysis/summary hashes.
   - **Problem:** A controlled file change after acceptance and before freeze is enough. The changed CSV or metadata receives a new SHA while status remains accepted and full-call counts remain confirmed. A changed analysis table or summary can also be archived without comparing its accepted pin. Source/ELF checks do not cover these four evidence files.
   - **Fix:** For accepted cases, verify all four current evidence files against the hashes and lengths captured at acceptance. Reject freezing on any mismatch; retain the original accepted pins and mark the integrity failure. Only nonaccepted cases may acquire hashes for whatever partial files are visible, while retaining partial_unknown. Keep such observed hashes separate from accepted pins.
   - **If we skip it:** A completed manifest/archive can describe bytes that were never accepted by the fixed C analysis. Later independent arithmetic may catch the mismatch, but the manager's completed receipt would already be wrong about its evidence binding.

## Checked paths that did not produce another blocker

The complete 893-line runner and remote contract were read. All 140 manifest-pinned files match the current local byte counts and hashes; with the runner and manifest this is the intended 142-file layout. Physical ancestry, ordinary Linux/x86_64 identity, source equality, exact directory membership, exclusive output files, clean build environment, HOME preservation and six in-Cry temp/cache paths are explicit. Source_commit still needs the planned local Git-to-upload byte check; a remote string is not a Git proof.

E1 builds ordinary and sanitizer trees, checks compile/link flags and six ELF digests, verifies exact five-test inventory and actual verbose/JUnit success, and saves inspection output. The two fully successful configurations establish the path-derived 132 full-call qualification count. Partial qualification leaves exact counts unknown and only adds already proved complete configurations to the lower bound. ASAN_OPTIONS is explicitly detect_leaks=0; no LSan claim is made.

Each ordinary collector is accepted only after exit zero, one-line complete metadata, exact counts, fixture/source/reference identity, dumpable set/readback, CPU2/clock/getres and subsequent C-summary/table checks. Launched GNU timeout supervisors are distinguished from confirmed completed collector PIDs. Missing/incomplete metadata stays unknown. One completed collector establishes 50001 full calls; accepted timed calls remain separate. C metadata/exit scope flags remain false as generated by C.

E2 checks completed E1 state, all old frozen-tree member bytes, identical source/runner/six binaries and boot_id before creating its own batch. It does not rerun CTest or rebuild. Old E1 manifest bytes, old member bytes and the E1 archive are rechecked at export, while legitimate E2 additions are not treated as missing from the historical E1 snapshot. The external local download/verification, PID check and distinct password reconnect remain obligations of the calling workflow; the remote batch argument cannot prove those local events.

Command waits are capped by remaining 300-second work time. Collector GNU timeout is 15 seconds plus kill-after2; manager wait is at most20 and remaining time. Parent handled signals are masked while publishing Popen ownership, then cleanup checks the same live leader starttick before signalling, reaps its handle, and checks its group with signal0 for at most5 seconds. Unconfirmed cleanup blocks a frozen manifest/archive. SIGKILL or machine loss still has no complete-export promise.

The manifest is formed after final state/commands and excludes itself; archive includes it and is created exclusively outside ROOT but inside Cry. The separate final stdout carries archive SHA, avoiding self-reference. Thirty-second export failures retain partial path/status and do not return successful completed/archived. These checks do not fix the two ownership/integrity issues above.

## Actual review execution and limits

The reviewed source's pure `--selfcheck` was executed once with Python -B and exited0, reporting selfcheck true and zero explicit real-clock reads, file-data reads, SSH and crypto calls. No real run_once path, subprocess, C program, collector, filesystem batch or SSH was executed. An extracted pure cleanup predicate plus a memory-only model of the failed-claim finally flow confirmed that an empty command list permits export despite no batch ownership. A memory-only accepted-case assignment model confirmed that replacing the pin leaves accepted state unchanged. These are static/control-flow reproductions, not an actual concurrent-run or corruption experiment.

No docs, original evidence or commits were changed. This review does not certify actual Linux lifecycle recovery, ordinary machine-code timing boundaries, statistical assumptions, frequency constancy, measurement precision or R02/R04 acceptance. After repairs, review the changed paths and repeat only pure selfchecks before deployment qualification.

Not checked: real remote manager execution, actual Linux compiler/test results, sampling, local authentication/download sequencing and hardware failure recovery.
