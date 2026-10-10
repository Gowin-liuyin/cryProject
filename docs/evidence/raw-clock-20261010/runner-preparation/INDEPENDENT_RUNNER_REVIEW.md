# Independent fixed RAW runner review — round 1

Date: 2026-10-10. Reviewer: independent agent `raw_clock_design_review`. This is a same-model independent source inspection, not external Codex or cross-model review.

What this change does: The Python runner manages two fixed C11 tools on the user's stated Linux host and physical Cry subtree. It performs ordinary/sanitizer qualification, requests three sequential ordinary collector executions, invokes the ordinary C analyzer for each CSV, and exports source/log/output evidence. It does not calculate the clock distribution, connect SSH, handle passwords or modify global CPU resources.

## Reviewed bytes and limits

| File | Reviewed SHA-256 |
|---|---|
| `remote_run.py` | `3b29aa0825f3f599f8f80b54b67d0e9663f5835522f2baf00c1aaad50c114eb2` |
| `REMOTE_CONTRACT.md` | `4b1deceab97b7df734e5b296f2327beb6bb8b9b93239d1288a9e16b656d0ba2f` |
| frozen collector C | `ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd` |
| frozen analyzer C | `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0` |
| frozen CMake | `28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e` |
| frozen experiment plan | `7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a` |

No runner import, runner selfcheck, compilation, CTest, SSH, actual managed command, clock collection or signal fault-injection was executed by this reviewer. No credentials or sealed evidence were read or changed. The parent reports one in-memory runner selfcheck; this review does not independently rerun or certify it. Source review of the two C programs is recorded separately in INDEPENDENT_SOURCE_REVIEW.md.

## Must fix

1. **The launch counter counts timeout supervisors, not observed collector starts** (`remote_run.py`, lines 199–205 and 271–272).

   What this is: Each collector request starts `/usr/bin/timeout` through Popen. The case becomes `launched` and `launched_processes` increases as soon as that Popen succeeds.

   Problem: If timeout itself cannot fork or execute the collector, the existing state still reports one launched process as though it were a collector. Popen here proves only that its immediate timeout supervisor started. The collector PID is available later from accepted metadata, and a failed or empty attempt can leave actual collector start unknown.

   Fix: Name the counter/state explicitly as supervisor launches (for example `launched_supervisors` and `supervisor_launched`). Retain separate metadata-confirmed completion and accepted-pair counters. Document that failed supervisor attempts do not establish an actual collector start or a zero-pair result.

   If skipped: Failure-state counts can overstate executed collector processes and blur the planned/observed distinction required by this study.

2. **The case loses its unknown flag before C validates its CSV** (`remote_run.py`, lines 281–295).

   What this is: Successful collector metadata sets `partial_unknown=False`, while the C analysis runs afterwards. Only after analysis does the runner set management acceptance and increment `accepted_pairs`.

   Problem: If analysis rejects an incomplete or internally inconsistent CSV, times out, or fails to publish its output, the case remains `collector_completed` with `partial_unknown=False`. Metadata-confirmed collector completion is a valid separate fact, but it does not imply a completely accepted case or known valid pair sequence. The overall failed state and zero accepted increment do not remove that misleading per-case flag.

   Fix: Keep the collector completion fact/counter, but leave case-level `partial_unknown=True` until both metadata and C analysis acceptance finish. Alternatively, name a separate collector-only unknown flag and an explicit case-accepted flag; do not reuse one flag for both scopes.

   If skipped: A failed analysis case can look complete when read alone, despite never passing the strict CSV contract.

3. **A failed bounded reap can still be followed by a supposedly frozen archive** (`remote_run.py`, lines 209–217 and 302–334).

   What this is: On an exception, command sends SIGKILL to its own process group and waits up to five seconds for the immediate Popen child. The outer finally then writes the manifest and archive.

   Problem: The cleanup wait can itself time out or be interrupted by another catchable termination signal. Its failure propagates to the outer handler without an explicit unreaped-child flag; export can still succeed and report `archived`. The child has not been confirmed terminal/reaped, so output may remain mutable while the manifest and archive are read. Sending SIGKILL alone is not a completed wait. The documented frozen-manifest boundary is therefore stronger than this failure path proves. Python's [Popen wait contract](https://docs.python.org/3/library/subprocess.html#subprocess.Popen.wait) expressly allows TimeoutExpired before termination is observed.

   Fix: Record cleanup success/unknown explicitly. Temporarily block the catchable administrative signals during the already bounded cleanup wait, then restore the mask. If the five-second wait does not confirm termination, stop work and return `not_archived` with the original tree and known child/group identity preserved; do not claim a frozen archive of potentially active output. This is a narrow failure-state/export guard, not a request for a general supervisor or global process scanning.

   If skipped: An archive can be marked complete even though its files were not established immutable at sealing time, and child cleanup status is obscured.

## Should fix

4. **Describe the aggregate size check as a boundary budget, not a hard quota** (`REMOTE_CONTRACT.md`, resource/export paragraphs; `remote_run.py`, boundary and child_limits).

   What this is: RLIMIT_FSIZE is a per-file 64 MiB limit. The aggregate 256 MiB tree limit and one-GiB free-space admission are checked at boundaries, not continuously.

   Problem: A child can grow one or two output files between checks and overshoot the remaining aggregate allowance before the next boundary rejects it. No global disk quota or continuous aggregate limiter is installed. The current contract says when checks occur, but should state this peak-limit distinction explicitly rather than invite a strict aggregate-cap reading.

   Fix: State that the aggregate/free-space limits are boundary admission/stop rules with possible transient overshoot; preserve overshoot as failure. The archive writer's combined tree/archive cap is separately enforced on each archive write. No disk-quota platform is needed for this small fixed workflow.

   If skipped: Readers may interpret the stated budget as a hard peak bound that this implementation does not enforce.

## Checked and consistent

- Root/commit arguments are constrained to the exact physical Cry child naming scheme. Initial admission rejects symlink ancestors/root/source, nonregular project entries, unexpected uploaded members and an existing archive. Stage boundaries recheck physical root, tree entry types and source/ELF hashes. File creation is exclusive; existing evidence is not overwritten or deleted. These are trusted-user administrative boundaries, not an adversarial concurrent-mutation guarantee.
- The source pins match the inspected current collector, analyzer and CMake bytes. The source commit is properly documented as a provided deployment identity rather than a remotely proven Git object. Runner hash is recorded and pinned during its own execution. All four built ELFs are recorded, and later boundaries recheck them. Only ordinary ELF paths are used for collection and offline analysis.
- The cleaned child environment retains the login HOME value rather than repurposing it. All specified temporary/cache destinations are inside the new Cry tree. Fixed commands have fully qualified paths, argv lists, no shell, no SSH/password/credential handling and no arbitrary-command option. The inspected CMake and C tools do not contain a project-file write to HOME.
- Both ordinary and dynamic builds include the two fixed executables and exactly the two registered selfchecks. The runner reads CTest inventory before each full CTest execution and stops dependent work on any failure. Format-tool auto-discovery is absent from the pinned CMake, so an unrelated system formatter is not an unplanned configure gate.
- The launch critical section blocks administrative signals until Popen identity and counting are registered. Children start a new session and unmask signals before executing their fixed command. Exceptions target only the registered own process group, without name-based or system-wide process killing. The cleanup-completion issue is specifically finding 3; initial process creation remains subject to OS scheduling/blocking and is not a hard-real-time guarantee.
- Configure/build share a 60-second allowance; CTest has its own 30-second limit. The work phase has a 300-second timer, and export gets a new 30-second timer after work stops. No compilation or collector starts are scheduled during export. Bounded waits/timers remain engineering deadlines rather than hard bounds on kernel-uninterruptible operations.
- Collector metadata checks strict integer-versus-boolean types for counts/UID/error values, fixed protocol/RAW clock, completion, CPU2 affinity and getcpu, successful metadata reads, coherent timespec arithmetic and unchanged clocksource/resolution. Different accepted collector PIDs and kernel releases are checked. This administrative acceptance does not compute any clock distribution or replace the C CSV validator.
- `accepted_pairs` increases only after an ordinary C analyzer success; planned 303000 pairs are not automatically counted as measured. C analyzer's false metadata-check fields stay unchanged, while management acceptance is recorded separately. Finding 2 concerns the earlier per-case unknown flag, not the accepted-pair arithmetic.
- The manifest dictionary is evaluated before manifest.json is created, so it excludes itself. It includes previously written environment, command and state records. The archive lives beside the root, not inside it; relative regular-file members avoid archive self-inclusion. The combined archive/tree writer checks each compressed write against remaining budget.
- No sealed state file is changed after archive creation. `archive_status=see_supervisor_stdout` in the tree intentionally avoids a self-referential archive digest, while compact supervisor stdout returns the actual archive SHA/status. Archive failure returns nonzero/not_archived and retains partial archive/originals. This is coherent once finding 3 prevents sealing an unconfirmed active producer.

Verdict: Fix 1–3 and clarify 4 before real remote execution. No generic platform, additional root access, user reconfirmation or unrelated experiment is required. Actual Linux qualification, real collector execution, output/manifest/archive verification and clock-precision claims remain outside this static review.
