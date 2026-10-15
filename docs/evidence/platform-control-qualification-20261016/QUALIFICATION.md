# 平台频率管理器空任务资格结果（2026-10-16）

状态：**五条空任务全部通过**。本文只记录真实执行结果；三条尝试的失败原件全部保留，
最终资格对应第三次尝试（控制根 `Cry/platform-control-20261016-b7e21f4c9a03`）。

## 固定输入身份

| 项 | 值 |
|---|---|
| 冻结 PLAN | `docs/evidence/platform-control-20261016/PLAN.md`，sha256 `feeaae127586101f2e6c2f037fc4e865b3074a319595a530c9d3eff1f3298601` |
| 控制器源码 | `tools/platform_control/controller.py`，sha256 `4a0cf57a00c6802ff86ed410bd2518bc56cc8e694422cbc4ea7a24a3f1cdd701`（提交 `a3c9ca1`） |
| 控制根 | `/home/nss-marker/yhr/Cry/platform-control-20261016-b7e21f4c9a03` |
| 状态根 | `/home/nss-marker/yhr/Cry/platform-control-20261016-state`（root 0700） |
| 主机 | `nss-m`，Linux 6.17.0-35-generic，x86_64，AMD Ryzen 9 9950X，32 线程；`boot_id=1d5a4300-d997-4a45-a9d6-95165d68dcd9` |
| 起始频率基线 | `global_boost=1`；全部 32 个 policy `powersave` / `min=2982259` / `max=5756452` / `epp=balance_performance` |

## 资格矩阵（第三次尝试，全部真实执行）

| 运行名 | CPU | 空任务 | deadline | 控制器退出 | `reason` | `worker_exit_code` | `worker_drained` | `restore_match` | 独立前后快照 | active 指针 | 两锁 |
|---|---:|---|---:|---:|---|---:|---|---|---|---|---|
| q-normal | 2 | `/usr/bin/true` | 3 s | 0 | `worker_finished` | 0 | true | **yes** | 未变 | 已清空 | 可获取 |
| q-failure | 2 | `/usr/bin/false` | 3 s | 1 | `worker_finished` | 1 | true | **yes** | 未变 | 已清空 | 可获取 |
| q-timeout | 2 | `/usr/bin/sleep 20` | 2 s | 1 | `worker_timeout` | −15 | true | **yes** | 未变 | 已清空 | 可获取 |
| q-controller-loss | 6 | `/usr/bin/sleep 20` | 5 s | 137 | `controller_lost` | −15 | true | **yes** | 未变 | 已清空 | 可获取 |
| q-contention | 6 | `/usr/bin/true` | 3 s | 1 | `[Errno 11] Resource temporarily unavailable` | 不适用 | 不适用 | `not_required` | 未变 | 已清空 | 由外部持锁者持有 |

`q-contention` 的 `restore_match` 是 `not_required` 而不是 `yes`：该请求在
`partition-admin.lock` 上被拒绝，**在任何频率写入之前**退出，`Transaction` 从未建立，
因此没有可恢复的配置。它满足的是"未产生任何配置改动"这一更强的条件，独立前后全量快照
逐字相同（`raw/attempt3-logs/q-contention.state.diff` 为空），运行目录未被创建。
本页如实区分这两种恢复语义，不把 `not_required` 记成 `yes`。

进入/运行中/退出三处频率证据来自控制器自身落盘的 `baseline.json`、`during.json`
（`q-timeout` 41 个样本、其余 1 个）、`0020-restored.json`，加上主控独立的
`*.before.txt`/`*.after.txt` 全 32 policy + `global boost` 快照。放行门实测：

| 运行名 | 探针 n | min kHz | max kHz | 跨度 kHz | 全部在 4300000 ±2% |
|---|---:|---:|---:|---:|---|
| q-normal | 20 | 4298140 | 4316261 | 18121 | 是 |
| q-failure | 20 | 4300000 | 4300000 | 0 | 是 |
| q-timeout | 20 | 4300000 | 4315885 | 15885 | 是 |
| q-controller-loss | 20 | 4300000 | 4300000 | 0 | 是 |

## 三次尝试与自行修复

| 尝试 | 控制根 | 结果 | 失败原件 |
|---|---|---|---|
| 1 | `platform-control-20261016-47033dd864ca` | `q-normal`/`q-failure`/`q-timeout` 通过；`q-controller-loss` 被 `frequency_probe_rejected` 拒绝 | 该根 `failed-attempt-1/` |
| 2 | `platform-control-20261016-a3c9ca1e6f9b` | 断言层全过；但主控的外部快照在 guardian 尚未排空时取样，得到 `INDEPENDENT_STATE_UNCHANGED=no` 的假阴性 | 该根 `failed-attempt-2/` |
| 3 | `platform-control-20261016-b7e21f4c9a03` | 五条全过，快照在排空后读取 | 本页原始日志 |

尝试 1 的根因（实测数据，不是推测）：CPU6 的 20 个探针里首样本 `4150137 kHz`，低于
`4300000 × 0.98 = 4214000`。写入与回读在该样本之前已全部确认成功
（`boost=0`、`policy6 max=4300000`），说明它读到的是 amd-pstate 写后过渡期的旧工作点。
修复提交 `a3c9ca1`：写入与回读全部完成后**固定沉降 1.0 秒**再取 20×50 ms 样本；
接受带（±2%）与跨度（≤50000 kHz）判据保持不变，不做重试择优、不按结果追加采样。
沉降间隔与判据同时写进 `tools/platform_control/README.md` 与冻结 PLAN。

尝试 2 的根因在**主控的验证脚本**而不在控制器：`controller-loss` 前台被 SIGKILL 后，
guardian 仍需要时间终止 worker 组并逐项恢复。尝试 3 在控制器退出后轮询
`controller.py run` 进程与状态根 `active.json`，实测排空耗时 0.25–0.50 秒，之后才取结束快照。

## 结束核对（第三次尝试之后）

- 无残留 `controller.py`/guardian/worker/空任务进程。
- `/home/nss-marker/yhr/Cry/platform-control-20261016-state/` 为空，无 `active.json`。
- `partition-admin.lock` 可重新加排他锁（`LOCK_FREE`）。
- 全部 32 个 policy 回到 `powersave` / `min=2982259` / `max=5756452` / `epp=balance_performance`，
  `global_boost=1`，与进入前基线逐字相同。
- `q-contention` 的外部持锁者在资格期间确实持有共享锁；该测试进程由主控在核对后回收。

## 边界

本资格只证明工程控制路径与恢复路径可用：单任务互斥、worker 生命周期、截止时间、
前台进程被 SIGKILL 后 guardian 的恢复、以及退出后配置逐项回读一致。
它**不**证明逐调用物理恒频、不构成物理误差界，也不代表 CPU2/CPU6 上已经没有其他工作负载；
`scaling_cur_freq` 是内核暴露的工程观测量，不是示波器测量。

## 原始件索引

- `raw/qualify-attempt3.log`：第三次尝试完整 stdout（含每条用例的前后快照 diff、post 检查）。
- `raw/attempt3-logs/`：32 policy 快照与 post 检查原件。
- `raw/attempt3-runs/*/`：控制器落盘的 `baseline.json`、`entry-probes.json`、`during.json`、
  `0020-restored.json`、`guardian.json`、`worker.json`、`terminal.json` 与逐写 intent/visible 序列。
- `raw/qualify-attempt1.log`、`raw/qualify-attempt2.log`：两次失败尝试的完整 stdout。
