# Ordinary repeatability manager: final independent repair review

What this change does: The repair gives exclusive batch creation a signal-safe ownership flag. It also preserves accepted hashes and lengths for all four case outputs, checks them before freezing, selects Unix Makefiles explicitly and records successful command output lengths.

**The two findings in REMOTE_STATIC_REVIEW are closed for this final source. No new blocker was found in the delta and related control flow.** This is a same-model internal independent bounded review; external Codex MCP is unavailable and remains pending. It does not claim a real remote run or lifecycle experiment.

Final runner SHA256: `00ba8794453f462d4a398b70692049db8e63dcd886f19c27a74b53159794f1a9`. Remote-contract SHA256 remains `ccb0ec975d52bcbfda5acec69784cdde6604b9114533976d37c284d1fe315fc2`; source-manifest remains `c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552`; plan remains `90ced1f1d1157f80997f5af3e2afaeb83c7bf8a488c00c229ac77d55d7cd70ec`. The initial runner `40b74f05...`, its preserved source snapshot and the original changes-required review remain unchanged. This page is an additive repair decision, not a rewritten initial review.

## Finding 1: closed

Batch ownership starts false. The manager blocks all handled signals while attempting exclusive mkdir and setting both its local ownership flag and state flag. The previous signal mask is restored only after this transition. If mkdir fails, ownership remains false.

The first finally branch checks that flag before any batch finalization. An unowned invocation cancels its timer, prints a separate failed/withheld_no_batch_ownership receipt and returns1. It does not create the other run's after-environment, commands, state, manifest or archive. `ownership_allows_freeze` also requires strict boolean true and confirmed cleanup. The original losing-claim path therefore no longer reaches export.

## Finding 2: closed

Acceptance now saves lengths as well as SHA256 for CSV, metadata, C table and C summary. Their accepted pins are retained. `current_output_pin` checks physical ancestry, a regular file, current length and SHA, and rejects a length change during hashing.

Before freeze, all four observed records must match the accepted records. Missing, nonphysical/nonregular, wrong length or wrong digest makes the case's unchanged flag false and raises an integrity failure. The enclosing handler marks the batch failed and sets export_pin_failure; commands and state may be saved as failure evidence, but manifest and archive creation are then withheld. It does not replace accepted digests with the new observed ones. Nonaccepted cases only get a separate current_visible_outputs record and keep their partial status.

The extracted pure predicate independently rejected 30 malformed cases: for each of four outputs, missing entry, nonregular marker, integer1 in place of true, boolean/changed length, changed or null digest; plus extra output and nonaccepted state. A matching four-output dictionary passed. Unowned empty-command freezing and cleanup-unconfirmed/group-present freezing were separately rejected.

## Other delta checks and actual execution

The explicit `-G Unix Makefiles` matches the link.txt inspection path. Adding stdout_bytes/stderr_bytes on the successful command path does not alter launch, cleanup, return-code or sampling behavior. The source/ELF, E1/E2 dependency, remaining deadline, unknown-count and archive rules reviewed initially remain otherwise unchanged; this repair is not a fresh certification of those runtime paths.

This reviewer executed the final source's pure `--selfcheck` exactly once with Python -B. It exited0 and reported selfcheck true, zero explicit real-clock reads, file-data reads, SSH calls and crypto calls. The additional 30-variant test ran only extracted dictionary predicates and did no filesystem batch I/O. No real run_once, C, CTest, SSH, collector, full algorithm or sampling path was executed. No docs, old review, evidence or Git commit was changed.

Execution accounting stays separate: the implementation handoff reports four developer selfchecks (two initial and two repair, with one on final00ba source). This reviewer previously ran the initial pure selfcheck once, and now ran final00ba once independently. The extracted predicate checks are another memory-only check, not another manager run or C qualification. Developer history is attributed to the handoff; this page directly witnesses only this reviewer's own executions.

Verdict: Ship.

Not checked: actual Linux manager execution, compiler/ELF/test results, remote sampling and recovery, password reconnect/download sequencing, or protection against arbitrary concurrent hostile filesystem changes. Keep those within their planned real-evidence gates; R02/R04 remain partial.
