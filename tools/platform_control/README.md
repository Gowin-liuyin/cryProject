# 平台串行频率管理器

本目录只管理频率请求、原生 C worker 生命周期和证据；不实现计时或统计。新工具尚未执行真实配置资格；当前可执行入口须先由主控冻结计划、提交并通过空任务资格，才能用于 M2/M5/M3/M4。

```sh
cmake -S tools/platform_control -B build/platform-control
ctest --test-dir build/platform-control --output-on-failure
python3 -I -B tools/platform_control/controller.py --help
```

`controller.py run` 仅接受 Linux x86_64、经 sudo 启动的非 root 原用户。固定目标 CPU2 或 CPU6；全局 boost=0，目标 singleton policy 的 governor/EPP=performance、min=max=4300000 kHz。无自动重定目标。先保存全部可见 policy 控制/身份及全局快照，再逐写保存 intent、fsync、回读；20 次 50ms 间隔的当前频率均在目标 ±2% 且跨度不超过 50000 kHz才放行 worker。这只是工程观测门，不代表逐调用物理恒频。

空任务只允许固定运行名/精确命令：`q-normal`、`q-contention` 对应 `/usr/bin/true`，`q-failure` 对应 `/usr/bin/false`，`q-timeout`、`q-controller-loss` 对应 `/usr/bin/sleep 20`。运行名自动选择对应资格模式；显式 `--qualification` 必须相符，且不得忽略或替换用户传入的其他命令。其他运行名始终只接受 Cry 内 collector；不能用资格参数绕过路径边界。修复证据见 `docs/evidence/platform-control-fix-20261016/`，旧失败原件保留。

所有运行共同持有既有 `/home/nss-marker/yhr/Cry/partition-admin.lock`（只打开并 flock，不更改内容、不创建替代品），并持本控制根 `collection.lock`。因此换 CPU、换控制根及 recover 都互斥。新状态根为 `/home/nss-marker/yhr/Cry/platform-control-20261016-state/`，root 0700；首写之前创建 root 可信 `active.json`，未恢复/未排空/guardian死亡会保留指针并阻止任何下一次 run，不能把残留配置当作新 baseline。成功恢复并排空后才移除该指针；永久结果在运行目录。

每次控制根固定为 `Cry/platform-control-20261016-<12位十六进制nonce>`，只新建运行名，不覆盖旧文件。源码/PLAN 先上传到该根内，`run` 的输出为该根 `runs/<run-name>/`，state/日志 root 所有且 worker 不可写。baseline、身份、命令、源/ELF/PLAN摘要、boot_id、worker PID/start_ticks/PGID/SID/UID/实际亲和性均记录。worker 自身使用该运行 `worker/` 及其 `tmp/`、`cache/`，不重设 HOME；源码中的其他显式临时路径仍须由模块在执行前审查。

实际运行形态（先验证 sudo 可用；不传输、保存环境口令）：

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py run \
    --control-root <控制根> --run-name m2-cpu2-s1 --cpu 2 --timeout-seconds 300 \
    --plan <控制根>/PLAN.md --plan-sha256 <冻结PLAN的SHA256> \
    -- <Cry内普通collector绝对路径> <collector参数>
```

root guardian 单独 setsid，管理亲和性避开 CPU2/6，持两锁并成为唯一频率写入/恢复进程。前台 controller 只持唯一寿命 pipe 写端；worker 不继承该 FD 或锁，实际降权到 sudo 原用户并经 taskset 建立独立进程组。guardian 监视 EOF、SIGTERM/SIGINT、deadline、配置漂移及 worker 退出；先 TERM/KILL 自己的 worker 组、保留 leader 未回收以保护 PID/PGID 身份，再回收并在 finally 逐项恢复原请求、全快照比对。某字段失败继续其余字段，未知并发值拒绝覆盖。日志写满不阻止内存原快照的最佳努力恢复，但缺恢复证据不能签成功。

`terminal.json` 的成功需要 `reason=worker_finished`、`worker_exit_code=0`、`worker_drained=true`、`restore_match=yes`，且全局 active 指针消失。worker 故障、超时及 controller 单进程死亡的资格应分别记录；不能只凭 terminal 文件证明进程已经结束。主控在每轮后另读原 PID、实际配置与锁可用状态。

原生 worker 合同只接受不 fork、不 daemonize、不另建 session 的已审 C collector。管理器不隔离系统其他工作，也不更改 IRQ/SMT/cgroup。guardian 自身 SIGKILL/OOM、整机故障、SSH session cgroup 被整体清理及内核不可中断状态不享自动恢复保证；`setsid` 不能替代 cgroup 脱离。这些情况留下全局 active 阻断，并由主控先检查原 PID/组及 root 原件后决定恢复，不自动重跑。

独立人工恢复入口：

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py recover \
    --control-root <控制根> --run-name <原运行名>
```

recover 要求相同全局 active 指针、两锁、原 boot_id、sysfs 属性身份和 root 私有原快照匹配，原 guardian 不存在且 worker 组已空；不杀身份不明的残留进程。它写新的 `recovery-<nonce>/` 收据，不改旧终态；恢复成功才解除 active 阻断。无 active 的重复 recover 会拒绝，没有自动覆盖/强制选项。

本机 CTest 的模拟只覆盖控制事务与恢复故障，不冒充真实 guardian、root 可信状态、真实锁频或测量资格；实际资格合同见 `docs/evidence/platform-control-20261016/PLAN.md`。本路不 stage/commit/push，根 CMake 接线由主控处理。
