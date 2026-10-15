# 平台频率管理器空任务资格计划

2026-10-16（Asia/Shanghai）。状态：候选计划，待主控冻结本地提交；尚未执行真实配置或采数。

## 范围与来源

复用 M1 的 boost 关闭、performance/EPP、4300000 kHz、taskset、进入/运行/退出快照和 restore_match 口径；M1 原脚本、vendor 与证据保持只读。旧 `run-locked-31337.sh` 没有跨 CPU 锁、controller SIGKILL 保护和组回收，且在恢复执行之前置成功标志，故本轮不复跑它；只借鉴其已公开频率字段与快照格式。

执行源码为 `tools/platform_control/controller.py`；独立 CMake/CTest 为 `tools/platform_control/CMakeLists.txt`。先通过本机模拟，再由主控检查本计划与源 diff、运行 format-check、提交固定 hash，然后才允许下列真实空任务资格。计划冻结提交应写入主控执行记录；本页不预填实际成功。

## 真实执行前只读门

1. 使用主控已核验 SSH socket，确认 `nss-m`、Linux x86_64、内核、boot_id、真实 Cry 根及当前 CPU/policy/SMT 映射，不沿用旧快照当当前状态。
2. 只读检查 `sudo -n true`；若不可用，由主控交互处理，不保存或传递口令环境变量。
3. 核对 CPU2/6 是 singleton policy、性能调速器/EPP 支持、4300000 在声明范围内；确认全部控制属性、global boost 可读，记录当前全部 policy/全局值。
4. 既有 root `/home/nss-marker/yhr/Cry/partition-admin.lock` 必须是 0600 常规文件并空闲，不创建别名绕过锁。核对系统现有采集进程，主控确认 CPU2/6 当前没有本项目其他采数任务。
5. 云端新控制根只用 `Cry/platform-control-20261016-<12hex>/`；新全局阻断目录 `Cry/platform-control-20261016-state/` 只由 root 创建。两者真实路径无越界链接；源码、PLAN、构建、日志、缓存、tmp、归档和恢复原件均在这些新子树。既有锁仅 flock，不改内容。
6. 普通 Python 标准库管理器以 `-I -B` 执行，不写 pycache；worker 只有系统 true/false/sleep 空任务，无项目硬编码临时路径。至少 1GiB 可用空间。无需安装依赖、不使用 Docker、不改 HOME。

## 固定空任务矩阵

严格顺序，一项结束且独立核对恢复后才进入下一项。每项最多一次，不按结果追加采样；预探针拒绝、恢复不匹配或组未排空即停止资格，不进入任何正式采数。

| case / run-name | CPU | 空任务 | worker deadline | 预期与最低证据 |
|---|---:|---|---:|---|
| q-normal | 2 | `/usr/bin/true` | 3秒 | worker exit0，主控 exit0，restore_match=yes，原 PID 不存在，两锁释放，active 指针消失 |
| q-failure | 2 | `/usr/bin/false` | 3秒 | worker exit1，主控非0；仍排空并 restore_match=yes，active 消失 |
| q-timeout | 2 | `/usr/bin/sleep 20` | 2秒 | reason=worker_timeout，空任务被终止/回收，主控非0，restore_match=yes，active 消失 |
| q-controller-loss | 6 | `/usr/bin/sleep 20` | 5秒 | guardian 记录 worker 身份后前台 controller 仅杀自身 SIGKILL；guardian 收到EOF（或 ready pipe断开）回收空任务并恢复。单独核对 guardian/worker 原 PID消失、两锁释放、active 消失；前台137不能当恢复证明 |

sleep 只用于空任务恢复故障演练，不进入密码实现、测量窗口或统计样本。每项先保存完整 baseline、属性身份与计划/源码摘要，再请求 global boost0、目标 governor/EPP=performance、min=max4300000，原请求逐项撤销并回读。写入与回读全部完成后**固定沉降 1.0 秒**，再取固定 20 次、50ms 间隔的当前频率，要求全部落在 4300000±2%、跨度 ≤50000 kHz；沉降间隔固定、不做重试择优（第一次资格实测 CPU6 首样本 4150137 kHz 是写后过渡期的旧工作点，失败原件归档在控制根 `failed-attempt-1/`）；不自动重定频率、不补人为热身负载。任何不通过均保留失败原件，不声称锁频资格成功。

q-timeout 的 worker 已启动后，可由主控只增加一次 q-contention 尝试（CPU6，normal=true），要求因共用锁在 baseline/频率写入之前拒绝；它不形成第二个采数任务。若没有足够时窗可靠观察，不追跑该项，记录未执行，并保持主控串行排程。

## 证据与结束核对

每项保留 `baseline.json`、摘要、身份、root guardian PID/start_ticks/亲和性/cgroup、worker PID/start_ticks/PGID/SID/UID/实际 taskset、command/ELF/源码/PLAN/boot_id、逐写intent/回读、entry-probes、active、during、restored、terminal、stdout/stderr。真实执行记录单独新建 `run-<commit>-<nonce>/`，不改本页或 M1 原件。

独立结束核对包括：所有原 guardian/controller/worker PID 与 start_ticks、对应组成员；当前全策略/全局稳定控制字段与各自 baseline 对比；调用者亲和性；两锁是否可取；全局 active 是否已清。日志归档存控制根内，拉回后逐字摘要比对。某步缺证据就记缺口，不能用终态JSON单独签收。

若 guardian 自身死亡或恢复失败，active 指针必须阻止新 run；先核对原件、原 boot_id、原进程与全部组已结束，才可以同锁执行显式 recover。恢复记录进入新 `recovery-<nonce>/`，旧证据不改。此轮不故意 SIGKILL guardian、不测试 OOM/整机故障、不宣称 SSH cgroup 整体死亡恢复。

## 资格之后

只有正常、worker故障、deadline和controller单进程死亡都通过，主控才可将此入口用于各模块已冻结 PLAN 的真实单调用采集。模块原生 C worker 不 fork/daemonize/setsid；各模块另核对源临时路径、普通 ELF、随机化、输入与窗口边界。CPU2/6由主控一人排程，dudect不进Holm。频率请求、sysfs当前频率及恢复只能支持工程控制描述，不证明逐调用恒频或物理误差界。
