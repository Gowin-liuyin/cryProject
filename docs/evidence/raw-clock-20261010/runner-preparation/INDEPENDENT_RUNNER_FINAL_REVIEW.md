# Independent fixed RAW runner final review

Date: 2026-10-10. Reviewer: independent agent `raw_clock_design_review`. Scope: narrow static follow-up to INDEPENDENT_RUNNER_REVIEW.md. The original rejecting review is preserved. Same-model independent review; no external Codex/cross-model review is claimed.

What this change does: The revised runner manages only the two frozen C11 RAW-clock tools in a fresh physical Cry subtree. It qualifies ordinary and dynamic Linux builds, requests three fixed sequential ordinary collector processes, accepts each CSV through the ordinary C analyzer, and exports an evidence tree only after its own child leaders and groups have been confirmed stopped.

## Reviewed identity

| File | SHA-256 |
|---|---|
| `remote_run.py` | `094a734afd11a5f6c956009f13edc6c818fbca02f9a0869f1842b0cdc2965c60` |
| `REMOTE_CONTRACT.md` | `9ea1f7e6986d0e2c938d520fba7b481ae0830ded27a43351b14030ee389d724b` |
| `raw_clock_calibration.c` | `ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd` |
| `analyze_raw_clock.c` | `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0` |
| `CMakeLists.txt` | `28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e` |
| `EXPERIMENT_PLAN.md` | `7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a` |

The actual confirm_cleanup, command, final export path, case/counter transitions, cleanup predicates and revised administrative contract were read. The current source pins exactly match the three source/build files above, and the plan pin matches the frozen plan. No import or execution of the runner, selfcheck, subprocess, compilation, CTest, SSH, hardware read or collection was performed by this reviewer. Creating this review file is the only mutation made. Parent-provided software qualification and source-commit reports remain separately evidenced work, not tests performed or independently recertified here.

## Finding closure

1. **Supervisor and collector starts are now distinct.** `launched_supervisors` advances only after Popen has returned its immediate child identity; the case records supervisor_started and supervisor_pid. Collector_started/collector_completed begin as null and become true only after complete accepted collector metadata supplies a distinct collector PID. A timeout wrapper failing to start the collector therefore no longer impersonates an observed collector launch. Planned process/pair counts, metadata-confirmed completed_processes and C-accepted_pairs remain separate.

2. **Case unknown status now persists through C analysis.** Metadata confirmation records collector_metadata_completed and the collector completion fact/counter, but leaves partial_unknown true. Only after ordinary C analysis succeeds, its output schema/row count are checked, and original CSV/metadata digests remain unchanged does the runner set management_complete_metadata_acceptance, case status accepted, partial_unknown false, and accepted_pairs +=101000. An analysis failure preserves the valid collector-completion fact while leaving the case unknown/unaccepted. Core CSV arithmetic/statistics remain in the frozen C analyzer.

3. **Unconfirmed cleanup now prevents sealing.** Both normal and exceptional command paths call confirm_cleanup. Catchable administrative signals are blocked for its bounded five-second cleanup, and leader_reaped/process_group_gone are initialized false before work. Group SIGKILL is sent only while the original immediate child has not yet been reaped; after a successful reap the old PGID receives only signal-zero existence checks. Cleanup records are finalized before the previous signal mask is restored, so a pending signal cannot erase the observed completion/unknown state.

   The group disappearance check is conservative: a remaining group, timeout, permission/error condition or interrupted/failed wait keeps cleanup unconfirmed. The aggregate cleanup flag is sticky, and export_is_safe also requires explicit true leader/group confirmation for every registered immediate child. On failure, the final path records known original PID/PGID facts, sets all_child_work_stopped to null, forces failed/not_archived, preserves the potentially mutable tree, and deliberately does not write manifest.json or create an archive. This closes the previous active-output/frozen-archive contradiction without scanning or killing unrelated processes.

4. **Aggregate quota semantics are explicit.** The administrative contract now distinguishes the per-file 64MiB RLIMIT from the 256MiB stage-boundary budget and expressly says the latter is not a filesystem hard quota. Between-boundary growth is not certified as a hard peak bound. The archive writer still checks every compressed write against remaining combined tree/archive space; a failure preserves originals/partial archive and cannot return archived success.

## Retained and bounded safeguards

- Startup still requires the exact fresh physical Cry path, correct commit-prefix syntax, only the four uploaded regular source files, no symlink/special members, no existing archive, ordinary Linux/x86_64 execution, CPU2 availability and free-space admission. Output creation is exclusive. Runtime boundaries retain source/runner/ELF digest checks and physical-tree checks.
- HOME remains the login value. Explicit temp/cache paths remain in the fresh Cry tree. Only fixed argv tools and fixed local ELFs are executable choices; there is no SSH/password, arbitrary command, root, MSR, crypto, frequency, cgroup or global resource-setting entry point.
- Signal blocking during Popen registration preserves a known immediate-child identity before parent handlers can raise. Per-command own-session groups, bounded cleanup and conservative group readback do not assert protection against SIGKILL of the supervisor, whole-host failure, hostile same-user mutation or uninterruptible kernel behavior. A source-review pass is not a hard-real-time guarantee.
- Ordinary/dynamic builds remain separate; each must expose exactly the two frozen selfchecks and pass both before any actual collector can start. Only ordinary collector/analyzer paths serve the three fixed cases. Configure/build, CTest, collector/analysis, total-work and export deadlines retain the frozen contract values. The new cleanup predicates have in-memory positive/negative fixtures in source, but this reviewer has not run them or claimed real signal-failure coverage.
- With cleanup confirmed, command files are closed before sealing. State/commands/environment precede the manifest; manifest evaluation excludes itself; the archive is a same-Cry sibling with relative regular-file members. No sealed tree record is rewritten to insert its own archive hash. Actual archive SHA/status remains in supervisor stdout and must be captured and independently checked by the caller.

## Final scope verdict

**Bounded source-review pass.** No outstanding blocker was found in the reviewed revisions for one authorized execution of this fixed administrative contract. This verdict permits proceeding through the already declared runtime preflight and Linux ordinary/dynamic qualification gates; it does not bypass them or assert they have happened. If an actual gate, lifecycle check, output check or budget fails, the fixed stop/unknown/not_archived behavior applies with no result-dependent replacement run.

The permissible research result remains three nearby empty-window descriptions, at most 303000 accepted pairs if all three actual cases pass. The review does not certify absolute clock accuracy, hardware tick size, full-decap process repeatability, iid, a constant-frequency condition, per-call overhead correction, R02 or R04 sign-off. Actual deployment, Linux software evidence, collector output completeness, group disappearance, archive byte verification and result-to-claim review remain execution/evidence obligations.


## Startup-observation addendum — final operative runner identity

Date: 2026-10-10. Narrow read-only follow-up. The final reviewed runner SHA-256 is now `bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04`; the administrative contract SHA-256 is now `a3530fd394136a8f605c7935d2ae8b401ec3d331622a3d2052d635375e771ac2`. Earlier reviewed identities above remain as history.

Removing exactly the seven-line startup-observation insertion reconstructs the preceding full runner SHA-256 `094a734afd11a5f6c956009f13edc6c818fbca02f9a0869f1842b0cdc2965c60`. No parameter, source pin, count transition, command, cleanup, deadline, manifest or archive code changed.

The insertion reads this process's own `/proc/self/stat` and uses `rsplit(")", 1)[1].split()[19]`, correctly identifying field 22 after the parenthesized command name; `os.getpid()` supplies this supervisor's PID. It exclusively creates run-claim.json in the already admitted fresh physical root and emits a supervisor_started event before child commands begin. Collector starts remain null and accepted pairs are correctly zero at that event. Failure of this initial read/write/output aborts dependent work through the existing exception/finally path; it does not manufacture a live collector or a completed measurement.

The existing first-run gate still allows only source/ before admission, so the new claim file prevents that tree from being admitted as fresh on a later attempt. If sealing is allowed, the claim is an ordinary immutable payload included by the later manifest and archive, without self-reference or post-archive rewriting. The contract explicitly distinguishes this event from collector start/data completion, requires actual PID/start-tick liveness checks after an observation interruption, and identifies the final stdout line as the actual archive receipt. A claim file alone is not a verified live process handle.

The bounded source-review pass remains valid for these final bytes. No new blocker was found. This reviewer did not execute the updated runner, its selfcheck, any process probe, SSH, or collection; the parent's reported in-memory selfcheck is not treated as actual lifecycle coverage.
