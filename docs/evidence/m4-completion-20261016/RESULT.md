# M4 Binsec 有界验证与采集软件准备

**定位/形式化：** Binsec 0.11.3 + Z3 4.15.3 实际验证同一对 Linux i386 ELF：公开长度 1–16、秘密数组 16 字节。提前退出版本在 `0x8049047`（`compare_early.c:9`）给出秘密控制流反例，状态 `insecure`；归约版本状态 `secure`，限定于下述有界模型。两者工作队列已空，所有路径到达指定 halt，pending、cut、discontinued、solver unknown 均为 0。

**统计：** 本轮未执行 `--collect`，没有 M4 原始时间 CSV、在线 dudect 测量或 CI/Holm/RTLF 结果。新增普通采集和在线 dudect 二进制已编出，输入/参数/描述检查通过；统计合同仍为草案，须主控冻结并提交后采数。

**边界：** 本例仍是人工相等性校准，不是实际 KEM、CVE 或密钥恢复。形式目标为 i386 `-O1`、最长 16 字节的抽取内核；有界 secure 不外推到 32 字节普通采集 ELF、任意长度、完整 KEM、其他编译条件或物理恒时。已提交的夹具与旧证据原件不变。

| 同一模型 | 提前退出 vulnerable | 归约 ct |
|---|---:|---:|
| Binsec 状态 | insecure | secure（有界） |
| 控制流检查通过/总数 | 49/50 | 33/33 |
| 访存检查通过/总数 | 235/235 | 141/141 |
| 总路径 / 到达 halt | 32 / 32 | 16 / 16 |
| pending / cut | 0 / 0 | 0 / 0 |
| discontinued 各原因 | 全 0 | 全 0 |
| SMT unknown | 0 | 0 |
| 最大深度 / 上限 | 134 / 10000 | 139 / 10000 |
| 进程退出 | 0 | 0 |

入口 `m4_entry`，终点 `m4_halt`；在消费比较返回值前停止，比较结果本身允许公开。`m4_secret_input` 的全部 16 字节为秘密，`m4_public_input` 16 字节及公开 `m4_public_length` 为两执行共享的任意公开输入，约束 `0 < length < 17`；具体栈指针。反例选取公开长度 16、公开全零，秘密低位 `ff` 与全零，命中提前返回分支。完整反例值和字节序以 TOML 为准。

采用 `-sse -checkct -checkct-features control-flow,memory-access -smt-solver z3`，分析 120 秒、单查询 5 秒、额外墙钟 180 秒；本轮均自然完成，无 timeout。固定长度16的备用脚本未运行，因为主合同已完整探索。

原始材料：

- [提前退出日志](formal-v1/vulnerable-1-16/stdout.txt)、[TOML](formal-v1/vulnerable-1-16/checkct.toml)。
- [归约日志](formal-v1/ct-1-16/stdout.txt)、[TOML](formal-v1/ct-1-16/checkct.toml)。
- [源位置](formal-v1/source-location.txt)、各子目录 `disasm.txt`、`identity.txt`、`model.cfg`、`status.txt`。
- [Linux 普通软件检查](software-native/software-logs-v2/ctest.txt)和 [ASan/UBSan](software-native/software-logs-v2/sanitize-ctest.txt)各 7/7，只运行输入/描述/参数拒绝；macOS 两配置各 5/5，见 `software-local/`。

软件普通入口为 `platform_m4_measure_{vulnerable,ct}` 和 `platform_m4_dudect_{vulnerable,ct}`。前者计完整 32 字节 checked compare，输出与统计电池 `measure` 格式一致；后者调用原上游 `dudect_main`、保全原 ticks 和类序，dudect 不进入 Holm。两套计时口径、热输入条件和预定预算见 [统计草案](STATISTICAL_PLAN_DRAFT.md)。

依赖安装经历 GMP 非 PIC 的 Zarith 链接失败，原日志保留，另用 PIC 构建前缀修复；最终工具真实可用，未通过系统包或默认 Docker 层绕过 Cry 边界。环境与原件归档摘要见 [ENV](ENV.md)，具体安装记录见 `runtime/`。

---

## 本轮锁频端到端结果（2026-10-16，控制器 `a3c9ca1`）

采集件 `build-software-v3/platform_m4_measure_{vulnerable,ct}` =
`26869078…` / `90740bdf…`；三次运行 seed 31337-CPU2、424242-CPU2、31337-CPU6；
每类 10000 次、预热 100。18 次控制器运行（含截断对照与 online dudect）全部 `restore_match=yes`。

**1. 定位**：人工提前退出比较夹具（**人工构造校准**，非上游 CVE）。
vulnerable 臂 Memcheck 报秘密条件跳转，ct 臂 0 命中；
Binsec `-sse -checkct` 对抽取内核给 **insecure**（反例 `0x8049047`，`compare_early.c:9` 提前返回分支）
对 **bounded secure**（pending/discontinued/unknown 全 0）；把 `-sse-depth` 降到 5 得到 unknown，
证明退出码 0 不能单独判 secure。

**2. 统计**：家族 `m4_compare_arm_session_v1`，**m = 3 次运行 × 2 臂 = 6**，α 全族 0.05。
vulnerable 臂三次原始 p = **0 / 9.23e−25 / 3.14e−22**，ct 臂 = 0.386 / 0.438 / 0.399；
**Holm 拒绝 3 项，全部来自 vulnerable 臂**。家族合并 Δ = −3.74 ns，CI [−3.87, −3.62]，I² = 98.6%
（混合"泄漏臂 + 不泄漏臂"造成）；按臂描述性合并：vulnerable −4.089 [−4.215, −3.963]，
ct +0.055 [−0.363, +0.473]。
族外 online dudect：vulnerable max|t| = 356.6 / 396.9 / 395.6（`online_leakage_found`），
ct = 2.06 / 1.90 / 2.27（无证据），与 Welch 结论同向。
族外截断对照（`--compare-bytes 16`，vulnerable 臂）p = 6.25e−202 / 0.00563 / 4.44e−177，
同样在提前退出臂可区分；**不进 Holm**。

**3. 边界**：主路径量的是完整 `m4_compare_checked`，截断对照量的是内核
`m4_compare_bytes`，**两者边界不同**，不得当作"同一边界的两个长度"，跨长度差同时含
"少一次封装层校验"与"窗口变短"两个因素。Binsec 的 secure 是**有界**结论，
限定入口、长度、秘密/公开模型、探索边界与求解器状态，不是任意长度或硬件恒时证明。
本夹具的阳性不等于任何真实密码库存在同类缺陷。
