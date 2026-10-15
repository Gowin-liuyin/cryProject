# M3 人工秘密访存 LUT 完整解封装采数合同（本轮冻结版 v1）

> **版本说明（主控 2026-10-16 补录）**：本文件在冻结提交 `efca8a1` 之后经过一次**文档修订**
> （补录已实读的 ELF 摘要、把执行入口换成绝对路径、同步 T9/T2 交付语义、修正正文与已填摘要的不一致）。
> 本轮**实际采数使用的是冻结提交 `efca8a1` 中该路径的 blob**，其 sha256 逐字记录在
> [platform-collection-20261016/README.md](../platform-collection-20261016/README.md) 的「冻结计划」小节里，
> 也是控制器 `--plan-sha256` 校验通过的那个值。文档修订**没有**改变任何统计口径、类对、样本预算、
> Holm 家族与 m、α、停止规则或恢复合同。



- 模块 / 验收项：M3 秘密访存校准（**人工夹具**，非上游漏洞、非新 CVE）/ `D04`（前置 `D01`、`D02`，
  条件项 `D03`，后续 `D05`）。
- 冻结日期：2026-10-16（Asia/Shanghai）。
- 状态：**待主控本地提交后生效**。本文件在 `main` 上的提交是本轮采数的唯一授权前提（CMD07）。
- 上位文件：`docs/platform/COMPLETION_REQUIREMENTS.md`（G03–G09、D01–D06）、
  `docs/evidence/m3-completion-20261016/{REQUIREMENTS,ENV,RESULT,NOTES}.md`、`vendor/mlkem-native/PIN.md`。
- 取代关系：本冻结版**取代**同目录 `STATISTICAL_PLAN.md`（旧预注册草案）中与之冲突的口径，
  特别是旧草案的"6 个公开种子 × 2 版本、每类 4000、代数族 α=0.01、12 项"设计。旧文件保留原字节不改；
  旧草案自述"准备完成、尚未授权执行"，未产生任何时间样本，**没有已采数据被本文件作废**。
- 人工性声明：本夹具把消息位分解的 `{0,1665}` 选择改造成**秘密下标查表**，数学映射仍是 FIPS 203 的
  `Decompress_1`。它是**人工缓存/访存校准**，不得表述为上游安全公告、真实历史 CVE 或官方缺陷；
  结果**不计为第三个上游 CVE**（`D06` 为可选项）。

---

## 1. 固定对象

### 1.1 源码与身份

| 项 | 固定值 |
|---|---|
| 上游 | `vendor/mlkem-native/PIN.md` 固定的完整提交 `b3ba7b32773e657dd37f6f87bce82528459ad8a4`（根 tree `4cb8a67933a7f357e0f7b0dd45c0c6916050038d`） |
| 人工补丁 | `docs/patches/m3-mem-lut-toggle.patch`，SHA-256 `2ae5aed747344fb978b87530ac5016495991bc007f8a93fff872f1273ca3c925` |
| 补丁作用点 | `mlkem/src/compress.c` 的 `mlk_poly_frommsg`：开版用 `PLATFORM_M3_LUT_LEAK` 下的 `_Alignas(64)` 双行 `{0, MLKEM_Q_HALF}` 表按消息位取址；关版保留上游值屏障与常数时间选择 |
| 完整路径 | `mlkem_decapsulate → baseline_native_dec → indcpa_dec → indcpa_enc → poly_frommsg` |
| 构建方式 | 两版各自独立 overlay、独立静态库、独立 CLI 与 `measure`（`cmake/PlatformM3.cmake`，`PrepareVariant.cmake` 打补丁） |
| 本仓库基线提交 | `44c209af65546eb3df3bdf5b165f52a7ef76feab`（打包时 HEAD） |
| 源身份口径 | 工作区导出 348 个文件；`source-upload.json` 记录打包时存在未提交改动（`M CMakeLists.txt`、`src/main.c`、`src/measure.c`、`src/mlkem.c`、`tools/platform_control/*`）；**不能冒称单一纯净 Git 提交** |
| 源码载体（实读） | `docs/evidence/m3-completion-20261016/source-upload.json` 记 `source_upload_sha256 = 38098e0f31ec354c1b8e0205b2f65b8fd2ee2277ee9cbbb6a245a35741b9bb1a`（348 文件） |

**语义保留要求**：两版都不得跳过重加密比较、隐式拒绝或密钥验证；不得添加 sleep、空转、随机延迟、
运行期秘密输出；不得固定拒绝密钥或引入未定义行为。缺陷变体只改变有来源的目标时序机制。

### 1.2 编译器与选项

- 编译器：Ubuntu Clang `18.1.3`，`/usr/bin/clang-18`（远端 `build-ordinary` 实读）；CMake `3.28.3`。
- 普通采集构建 `build-ordinary`：C11、`RelWithDebInfo`、`-O2 -g -DNDEBUG`、无 LTO、无 sanitizer。
- `platform_m3_{on,off}_measure` 编译定义只有 `-DMLK_CONFIG_FILE="baseline_config.h"`，
  **不带** `BASELINE_ORDINARY_WORKLOAD`，因此类别数 = `INPUT_CATEGORY_COUNT` = 5
  （`valid/bit-flipped/random/message-zero/message-ones`），不产生 ordinary 基准的 3 类与 `.cost` 文件。
- sanitizer 产物（`build-sanitize/`，ASan+UBSan）只作功能资格，**不得**用于计时或统计。

### 1.3 采集用普通 ELF 的 SHA-256

M3 的 `measure` 不是独立 collector，而是产品 `src/measure.c` 链接 on/off 各自打补丁的 kernel。
远端存在**两棵**含普通 measure 的树，摘要不同（差异只能来自构建路径/调试信息，源 export 同一份 348 文件、
`sha256sum -c` 348/348 通过；probe 报警 PC 逐字相同 `0x10DCED`/`0x10DD15`）：

| 树 | on/measure SHA-256 | off/measure SHA-256 |
|---|---|---|
| 旧根 `<Cry>/platform-m3-20261016-8b6f2d91/build-ordinary/platform-m3/` | `fe5435ba563cdd57df2f78ac6c53005685af377c31e9da2a5000eea426bb1929` | `d62e39124660f758a6cc98b82b3bd9b8e41a45b0ccdc46a83bc6c6ddd73df4f0` |
| 新根 `<Cry>/platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/` | `a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7` | `8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d` |

（`<Cry>` = `/home/nss-marker/yhr/Cry`。）

| 角色 | 冻结值 |
|---|---|
| 采集（开臂 `secret-index-lut-on`） | `a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7` |
| 采集（关臂 `secret-index-lut-off`） | `8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d` |

**树的选择（主控裁决，2026-10-16 冻结）**：**选定新根**
`platform-m3-locate-20261016-4b102a339cc8` —— 它与本轮定位复验、Microwalk 探测和 online dudect
构建在同一棵树里，证据同源。上表两个占位符已按新根实读值填定；旧根 `platform-m3-20261016-8b6f2d91`
的摘要仅作历史记录保留在附录 A，**不用于采集**，也不构成未选分支。

**两棵树的摘要都不得混用**：本轮采数只用新根的两臂，两臂来自同一棵树、同一编译器配置。
实读命令与原始输出见文末附录 A。

### 1.4 采集工具链（固定）

| 项 | 固定值 |
|---|---|
| 频率/生命周期管理 | `tools/platform_control/controller.py`（唯一入口） |
| 统计电池 | `scripts/run_stats_battery.sh` |
| `platform_stats` | `<Cry>/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats`，SHA-256 `ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2` |
| RTLF | `<Cry>/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R`，SHA-256 `50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e` |
| 在线 dudect | 本轮未冻结 M3 在线适配入口；**不存在就不跑**，写 `blocked/not_run` |
| 主机 | `nss-m`，Linux `6.17.0-35-generic`，x86_64，AMD Ryzen 9 9950X 16-Core / 32 逻辑 CPU |

Microwalk/Pin（`D03`）为**条件优先项**：无 Pin 或 Docker 存储无法证明全在 `<Cry>` 内时按已有
`NOTES.md` 记录降级为 Memcheck 秘密地址定位，**不得**把 clone 或命令存在当作运行结果，
也不得填 Microwalk 成功。降级不阻断本 PLAN 的时序采数。

---

## 2. 类对与臂

### 2.1 臂（版）

| 臂名 | 定义 | 角色 |
|---|---|---|
| `secret-index-lut-on` | 应用 `docs/patches/m3-mem-lut-toggle.patch` 的**开版** ELF：消息位作为跨缓存行系数表的下标 | 被测机制臂 |
| `secret-index-lut-off` | **关版** ELF：上游值屏障 + 常数时间选择，无秘密下标查表 | **恒定控制臂**（constant control） |

两臂是**两个独立 ELF**，不存在"同一 ELF 内 on/off 类"这种开关；每臂内部的输入类由 `include/inputs.h`
的 5 类给出。关版是恒定控制：它检验"当目标机制被移除后，同一类对是否仍出现同样差异"，
用于把机制效应与环境漂移分开。**两臂整体耗时差本身不是泄漏证据**（见 §4.3）。

### 2.2 主类对（进入主检验，**每臂各跑一次**）

**class0 = `message-zero`，class1 = `message-ones`**；效应量 `mean(message-zero) − mean(message-ones)`，双侧。

**选择依据（实读）**：本夹具的目标机制是 `mlk_poly_frommsg` 用**消息位**作为
`platform_m3_message_bit_table[bit][…]`（`_Alignas(64)`，两行跨缓存行）的下标，隐藏的取值就是
INDCPA 解密出的消息位；`message-zero`/`message-ones` 正是"解封装重加密时分别形成全零/全一消息位"的
两个合法密文类（M3 既有 `STATISTICAL_PLAN.md` 与 PLAN 均已这样预注册）。因此这两个类是**该机制的
秘密相关对**：同 key、同类内重复同一密文、只差秘密消息位形态。
`valid`/`bit-flipped`/`random` 完整保留作功能与上下文数据，**不进本参数族**，也不因结果被替换。

### 2.3 对照类对（**不进主检验**，每臂各跑一次）

**class0 = `bit-flipped`，class1 = `random`**（**原名使用，不得改名成 `malformed-*`**）。
两者都是共享 `measure` 已有的输入类：`bit-flipped` 是合法长度密文的内容被翻转，`random` 是随机内容密文；
两者都落进**隐式拒绝**路径。**每个臂各跑一次**（开臂、关臂都要）。

**为什么不是"截断"**：本平台 ML-KEM-768 的密文在 API 层长度固定（1088 字节），
`mlkem_decapsulate` 入口先验长度，接口层**无法表达"截断密文"**——截断会在封装层被长度检查拒绝，
落不到完整解封装窗口。因此本轮对照条件取"**内容被破坏/随机的密文**"，不是截断。

**它不进主检验的理由**：该类对触发隐式拒绝/错误分支，其依赖来源是**密文内容被破坏**这一公开事实，
与主类对（重加密压缩路径上的**秘密消息编码**依赖）**不同源**；纳入同一 Holm 家族会用分支存在性/
噪声主导的对照项污染专门检验秘密依赖的家族，使全族 α=0.05 的 FWER 解释失效。
它只作族外稳健性/链路灵敏度检查，不进家族、不写进 `holm.csv`。

### 2.4 跨臂对比（**家族外**，受控对照/工程一致性检验）

`secret-index-lut-on` 与 `secret-index-lut-off` 的整体耗时对比**单列为受控对照/工程一致性检验**：

- 它**含二进制级常数偏移**（两份 ELF 的代码布局、寄存器分配与指令序列不同），因此
  **不作为秘密相关泄漏的主证据**，**不进入任何 Holm 家族**；
- 它只回答"换臂后调用开销量级是否与定位结论相容"这一工程问题，结论写入 RESULT 的定位/边界层；
- 不得用跨臂差异替代 §2.2 的臂内类对检验，也不得用它反推"关版仍泄漏/开版必然泄漏"。

---

## 3. 三次运行与预算

### 3.1 复制（replication）表

| run | 测试 seed | CPU | 臂顺序（合同的一部分） |
|---|---:|---:|---|
| `m3_r01` | 31337 | 2 | on → off |
| `m3_r02` | 424242 | 2 | off → on |
| `m3_r03` | 31337 | 6 | on → off |

- 臂顺序交替是预注册的一部分，不得因观察结果改序；六个采集进程**顺序执行**，
  禁止并行占用 CPU2/CPU6。
- run1 与 run3 同 seed、不同 CPU，用于区分"seed 相关"与"CPU 相关"；**不得**把两个 CPU 称作两台独立机器。

### 3.2 预算

| 项 | 值 |
|---|---|
| CLI（实读） | `measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE`（每类数量 1–20000） |
| 每类样本数 | **10000** |
| 每臂每次运行产出 | **5 类 × 10000 = 50000** 行完整解封装 |
| 主类对用量 | 每臂每 run 20000 行；全轮 **3 run × 2 臂 × 2 类 × 10000 = 120000** 行 |
| 全轮正式调用 | **3 run × 2 臂 × 50000 = 300000** 次完整解封装 |
| 预热 | 每进程 **100 次**（`src/measure.c` 实读：计时循环前 100 次完整解封装），预热**不进 CSV**，meta 记 `warmup_decapsulations=100`；全轮 6 进程 × 100 = **600** 次 |
| 对照类对 | 同一 CSV 内的 `bit-flipped`/`random` 各 10000 行 × 每臂（**无需额外进程、无需额外 ELF**），族外分析 |

- **窗口只包一次完整 `mlkem_decapsulate`**：两个 `CLOCK_MONOTONIC` 纳秒读钟之间夹一次完整解封装，
  两侧 `atomic_signal_fence`；输入制备、内存分配、Fisher–Yates/SHAKE256 类别乱序、结果消费、
  日志与 I/O **全部在窗口外**。
- **预热 100 次**（合同固定值）：每个采集进程在计时循环前执行 100 次完整解封装，预热样本**不进 CSV**；
  该值由 `src/measure.c` 实测（`warmup_decapsulations=100`）。未满足预热即视为该 run 无效。
- **全量保留长尾**：不截尾、不删普通长尾、不扣读钟开销、不把 ns 换算成 CPU cycles；
  原始五类逐条 CSV、原顺序、时钟单位全部保留。
- CSV 表头固定 `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  单位 `ns`；已存在文件必须失败（拒绝覆盖）。不允许跨 run/臂/seed/CPU 静默拼接 CSV。

---

## 4. 统计

### 4.1 独立 Holm 家族与 m 的推导

- 家族 ID：`m3_lut_arm_end_to_end_v1`。
- 家族成员：**在一次 run 的一个臂内**，对主类对做一次双侧 Welch 大样本正态近似参数检验
  `H0: mean(message-zero) − mean(message-ones) = 0`。
- **m = 3 run × 2 臂 = 6**（r01-on、r01-off、r02-off、r02-on、r03-on、r03-off）。
  推导：2 臂按 §2.1 定义，每臂在每次运行各产生一个主类对检验，故成员数 = 运行数 × 臂数 = 3 × 2。
- **α（全族）= 0.05**。Holm 逐步法：`p_(k) ≤ 0.05/(6 − k + 1)`，首次不拒绝即停止后续拒绝；
  原始 p、秩次、阈值、调整值与逐项判决全部保存。
- 每项报告：两类原均值/方差/样本数、SE、Welch t、自由度、**95% 大样本正态近似 CI**；
  明确为**正态近似口径，不是有限样本精确 Student-t**；CI 是单项描述区间，不冒称六项同时覆盖。
- 零方差、缺失 run、null p、下溢原样保留，**不得**缩小家族数或按零 p 伪造通过。
- 六项全部保留，**不得**按结果拆成每 run 的 m=2，也不得只保留开臂、丢弃关臂。

### 4.2 明确写在 Holm 家族之外

- **RTLF：α = 0.01，bootstrap 种子 2026101605，族外。** 每份主类对 CSV 各执行一次；二值结果
  **不转换成连续 p、不进 Holm**；零值阻塞时保留原值与明确状态，**不当阴性**。
- **online dudect：族外。** 本轮未冻结 M3 在线适配入口；未交付即写 `blocked/not_run`，
  **不得**用离线回放冒充在线，且**最大 t 不得转成伪 p、不得进 Holm**。
- **对照类对（§2.3：`bit-flipped` vs `random`，每臂各一次）与跨臂对比（§2.4）：一律族外**，
  只作描述性/工程一致性检查。对照类对取自同一份原 CSV，但必须单独输出，
  **不得**并入 `holm.csv`，也不得与主类对合并成一个家族。
- 定位层结论（秘密地址定位、反汇编、Memcheck）与统计层**分列**，互不替代。

### 4.3 与旧预注册的差异（需主控知悉）

旧 `STATISTICAL_PLAN.md` 拟"6 个公开种子 × 2 版本、每类 4000、**族 α=0.01**、12 项"；
本冻结版按主控本轮固定参数改为"3 run（31337/CPU2、424242/CPU2、31337/CPU6）× 2 臂、每类 10000、
**族 α=0.05**、6 项"，并新增家族外对照类对与跨臂受控对照。旧草案未执行、无样本，故不产生数据作废；
但其 α 与 m 不得与新合同混引。

---

## 5. 停止、复测与失败归档

### 5.1 停止规则（任一命中即停止，不进采数或立即中止）

- 本 PLAN 未提交，或提交后内容与执行清单不符；采集臂 ELF 的 sha256 与 §1.3 选定的新根实读值不符，
  或两臂来自不同树/不同编译配置；
- 采集 ELF 的 sha256 与 §1.3 冻结值不符，或开/关两臂来自不同树/不同编译配置；
- 软件资格失败：两版独立 NIST KAT、接口边界、随机源失败、64 公开种子 × 5 类完整字节等价
  （含原始未修改参考版）、拒绝类 `J(z||c)` 验证、严格 patch dry-run；
- 语义被破坏（跳过重加密比较/隐式拒绝/密钥验证）、出现 sleep/空转/随机延迟/秘密输出；
- 动态检查产物被当作计时产物；
- 远端路径越出 `<Cry>` 物理边界或符号链接越界；
- 频率/恢复合同未成立（§6 任一硬条件不满足）；
- 数据不完整（行数、类别数、表头、`time_unit`、meta `run_status` 不符）或进程异常退出；
- 出现密钥恢复、exploit、外部秘密类操作；Microwalk 降级未按 `D03` 留证而直接填成功。

### 5.2 复测规则

- **不得**因显著性或未显著而增样、追加种子、补跑或挑选成功进程；不得看结果后换类对、改臂序、改阈值、
  或按旧草案的 6 种子方案混采。
- 复测只允许在"失败已归档 + 原因已定位 + PLAN 修订并重新提交"之后**另立新目录**进行；
  修订版必须写清新失败原因与新固定参数，不得改写旧结果。
- 复测数据不得与首轮合并成更大族凑显著性；`D06`（真实历史访存例）为**可选**，不作为复测借口。

### 5.3 失败归档规则

- 失败原件**先归档再重跑**：把该次运行的原始 CSV、meta、日志、Memcheck/定位日志、控制/恢复日志
  按**原字节**复制到 `failed/<run_id>/`，写 `MANIFEST`（来源路径、摘要、失败原因、时间）；
  归档完成才允许启动新运行。
- 失败运行**不计入**家族成员数，也不从结果里消失：RESULT 必须列出已归档的失败尝试。
- 部分完成数据一律标 `incomplete/failed`，不得当成功样本使用。

---

## 6. 频率与恢复（G05）

- 唯一串行任务：全程由 `tools/platform_control/controller.py run` 持有既有 `Cry/partition-admin.lock`
  与控制根 `collection.lock`；换 CPU、换控制根、`recover` 互斥；CPU2/CPU6 不与其他模块采数重叠。
- **boost = 0**（全局）；目标 singleton policy 的 **governor = performance、EPP = performance**、
  **min = max = 4300000 kHz**（CPU2 或 CPU6）。
- **taskset 亲和性**由控制器建立独立进程组并记录实际亲和性；worker 不得 fork/daemonize/自建 session。
- **三次频率快照**：**进入前**、**运行中**、**退出后**各一次，保存全部可见 policy 控制值与身份、
  全局快照与逐字段回读；运行中另有 20 次 50 ms 间隔采样（均须在目标 ±2% 且跨度 ≤ 50000 kHz 才放行）。
- **`restore_match=yes` 才算有效**：`terminal.json` 成功需同时满足 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes`，且全局 active 指针消失；
  任一不满足该 run 无效。
- 异常退出**必须恢复**原配置后才能继续；恢复失败保留 active 阻断，由主控走独立 `recover`，**不自动重跑**。
- 请求频率与可见配置匹配**不等于**逐调用恒频；保留实际反馈与有限精度边界，不虚填恢复或频率认证。
- 全部原件、缓存、临时目录、日志与分析只在 `<Cry>` 物理边界内。

---

## 7. 执行入口（主控串行，固定形态）

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py run \
    --control-root <控制根> --run-name m3-r01-on --cpu 2 --timeout-seconds <T> \
    --plan <控制根>/PLAN.md --plan-sha256 <冻结PLAN的SHA256> \
    -- /home/nss-marker/yhr/Cry/platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/on/measure \
        m3_r01_on 31337 10000 <新目录>/m3_r01_on.csv <新目录>/m3_r01_on.meta
```

```sh
scripts/run_stats_battery.sh --input <原CSV> --format measure \
  --classes message-zero message-ones --output-dir <新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

族外对照（**每个臂**各一份原 CSV，各自的**另一个**输出目录，结果不并入 `holm.csv`）：

```sh
scripts/run_stats_battery.sh --input <该臂原CSV> --format measure \
  --classes bit-flipped random --output-dir <该臂对照新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

- 每个 (run, 臂) 一个**新** run-name、一个**新**输出目录；已存在文件必须失败。
- 主控另输出 `holm.csv`（假设 ID、原始 p、秩次、阈值、调整值、判决），不改写统计电池的单项结果。
- 跨臂对照另用独立目录与独立输出，**不并入** `holm.csv`。
- 对照类对取自同一份原 CSV 的 `bit-flipped`/`random` 两列类，用独立输出目录单独分析，
  **不需要**新增 ELF，也不得并入 `holm.csv`。
- `<T>` 由主控准入时按实测设定。

---

## 8. 三句结论模板（RESULT 必须逐字回答）

1. **定位**：人工 LUT 机制在**定位层**是否显示秘密地址依赖（开版报秘密地址/关版不报、反汇编与
   实际机器码范围），以及 Microwalk 是实际运行还是按 `D03` 可复核降级。
2. **统计**：本合同的 6 项臂内主类对 Welch 检验与 Holm（α=0.05）**实际**给出什么（开臂与关臂都必须
   逐项列出，含未检出与失败项）；RTLF（α=0.01）作为族外工具给出什么；跨臂受控对照的量级为何。
3. **边界**：这是**人工缓存/访存校准**，不是上游漏洞；结论只覆盖本固定输入、本机、本预算与本产物；
   **不可区分 ≠ 恒时证明**，定位阳性不保证该 ISA/缓存状态下有稳定端到端时差，跨臂差异含二进制级
   常数偏移、不作泄漏主证据。

---

## 附录 A：ELF sha256 实读记录

实读时间：2026-10-16 02:0x（CST），操作者 `plans`（task-7），**只读，未写入远端**。

命令（原始，逐字）：

```sh
# 选定的采集树（新根）
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry && sha256sum \
     platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/on/measure \
     platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/off/measure'
```

原始输出（逐字，选定的采集树）：

```text
a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7  platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/on/measure
8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d  platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/off/measure
```

未选（本轮不用于采集）的旧根历史摘要：

```text
fe5435ba563cdd57df2f78ac6c53005685af377c31e9da2a5000eea426bb1929  platform-m3-20261016-8b6f2d91/build-ordinary/platform-m3/on/measure
d62e39124660f758a6cc98b82b3bd9b8e41a45b0ccdc46a83bc6c6ddd73df4f0  platform-m3-20261016-8b6f2d91/build-ordinary/platform-m3/off/measure
```

**选定的采集树**（`platform-m3-locate-20261016-4b102a339cc8`）两臂摘要，本 PLAN 已直接复核，原始输出逐字：

```text
a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7  platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/on/measure
8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d  platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/off/measure
```

补充实读（补丁与工具）：

```sh
sha256sum docs/patches/m3-mem-lut-toggle.patch
# 2ae5aed747344fb978b87530ac5016495991bc007f8a93fff872f1273ca3c925
sha256sum /home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
# ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2
sha256sum /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
# 50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e
```

## 附录 B：待定项清单

| 项 | 状态 | 处置 |
|---|---|---|
| 采集两臂 ELF 摘要 | **已冻结（主控选定新根；`plans` 独立复核）** | 新根 `platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/{on,off}/measure`，`a371ed08…` / `8daaea28…`；旧根不用于采集 |
| `<T>` | 待定 | 单进程管理上限（秒），主控准入时按实测设定 |
| Microwalk/Pin（`D03`） | 条件项 | 实际探测后按 `NOTES.md` 记录成功或可复核降级 |

**对照类对不需要待填 ELF**：它取自同一 CSV 的 `bit-flipped`/`random`（§2.3）。
**本模块待填 ELF 占位符共 0 个**；`<T>` 与 Microwalk 两项不是 ELF 占位符。

## 附录 C：被取代的旧 PLAN 原文（逐字保留，便于追溯）

本目录原 `PLAN.md`（"M3 解封装路径夹具与功能/定位计划"）在本冻结版写入时**已被取代**。
该目录整棵为未跟踪新目录、无 Git 历史，故在此逐字保留原文；**其"不允许物理计时采样"的限定只适用于
旧定位阶段，本轮采数授权以本文件正文为准**。

```markdown
# M3 解封装路径夹具与功能/定位计划

日期：2026-10-16。对象是公开标注的人工访存校准，不是上游漏洞。
本计划只允许构建、功能测试与秘密标记动态定位；不允许物理计时采样或调频。

1. 固定 `vendor/mlkem-native/PIN.md` 的上游库，只在各自构建 overlay 中对 `mlk_poly_frommsg`
   应用 `docs/patches/m3-mem-lut-toggle.patch`。开版将消息位作为两个跨缓存行的系数表索引，
   表值 `{0,1665}` 直接参与重加密；关版采用上游值屏障与常数时间选择。
2. 两版各自编成独立静态库、CLI 和 measure；计时入口不执行。
   完整路径为 `mlkem_decapsulate → baseline_native_dec → indcpa_dec → indcpa_enc → poly_frommsg`。
   不跳过重加密比较、隐式拒绝或密钥验证，不添加 sleep、空转、随机延迟或运行秘密输出。
3. 普通与 ASan/UBSan 各执行开/关独立 NIST KAT 与接口边界、随机源失败、64 公开种子
   ×5 类输入的完整公开测试转录逐字等价（含原始未修改参考版）；拒绝类另验证 `J(z||c)`。
4. 原生 Linux 新目录必须为 `/home/nss-marker/yhr/Cry/platform-m3-20261016-<nonce>` 物理子树，
   源码、构建、临时、缓存、日志和结果均在该树内。最多并行编译 4 任务。
5. 动态探针只用公开确定性种子，在完整解封装前 poison 私钥的秘密多项式与拒绝种子，
   嵌入公钥与公开 hash 保持 defined；完整解封装后恢复标记再消费返回状态。
   标准 Memcheck 开版应报秘密地址、关版应不报；普通不带 poison 入口也检查内存错误。
6. 本次探测 Pin/Microwalk/.NET 与 Docker。若缺 Pin 或 Docker 存储不能证明全在 Cry，
   按平台计划降级为 Memcheck 秘密地址定位；不能把 clone 或命令存在当作运行结果。

统计采集另见 `STATISTICAL_PLAN.md`，必须由主控提交并冻结后独占 CPU2/CPU6 调度，
本路不采数、不写频率控制、不关闭共享 SSH socket、不 stage/commit/push。
```
