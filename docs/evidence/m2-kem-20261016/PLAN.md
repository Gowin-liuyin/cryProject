# M2 完整解封装时序采数合同（本轮冻结版 v1）

- 模块 / 验收项：M2 KyberSlash 完整解封装 / `B04`（前置 `B03`，后续 `B05`、条件项 `B06`）。
- 冻结日期：2026-10-16（Asia/Shanghai）。对象是**历史 Kyber768 round3（SHAKE）**，**不是 FIPS 203**；下游报告不得按 FIPS 203 署名。
- 状态：**待主控本地提交后生效**。本文件在 `main` 上的提交是本轮采数的唯一授权前提（CMD07：
  `git show <PLAN_COMMIT>:docs/evidence/m2-kem-20261016/PLAN.md`）。未提交前任何采集都无效。
- 上位文件：`docs/platform/COMPLETION_REQUIREMENTS.md`（G03–G09、B01–B07）、
  `docs/evidence/m2-kem-20261016/{REQUIREMENTS,SOFTWARE_CONTRACT}.md`。
- 取代关系：本冻结版取代同目录 `STATISTICAL_PLAN.md` 中与之冲突的草案口径（该草案自述"待主控提交冻结，
  尚未执行采数"），特别是"每进程固定同时产出 5 类"的旧预算。**旧文件保留原字节，不就地改写**。

---

## 1. 固定对象

### 1.1 源码与身份

| 项 | 固定值 |
|---|---|
| 仓库基线提交 | `44c209af65546eb3df3bdf5b165f52a7ef76feab`（`main`，打包时 HEAD） |
| 打包时未提交改动 | ` M CMakeLists.txt`、` M src/main.c`、` M src/measure.c`、` M src/mlkem.c`、` M tools/platform_control/README.md`、` M tools/platform_control/controller.py`、` M tools/platform_control/test_controller.py` |
| M2 适配接口 | `include/platform_m2.h`、`src/platform_m2_adapter.c`、`src/platform_m2_inputs.c`、`cmake/PlatformM2.cmake` |
| 未修历史提交 | `a621b8dde405cc507cbcfc5f794570a4f98d69cc`（Kyber768 round3，非 FIPS 203） |
| 已修历史提交 | `272125f6acc8e8b6850fd68ceb901a660ff48196`（KyberSlash1+2 修复对照） |
| 源码载体（实读） | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/source-upload.tar.gz`，SHA-256 `118aa44013b592a6e3265b23bc36978715bf6d96b705e48d8ef9e231805ee6b7` |
| 既有只读原件根 | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/`（575 源摘要 + 20 ELF 摘要） |

"打包时未提交改动"意味着**采集对象不是单一 Git 提交**，而是上述提交加上列改动的工作区导出。
主控必须在提交本 PLAN 的同一提交里同时冻结工作区导出摘要；导出摘要与本表不符即不得采数。

### 1.2 编译器与选项

- 编译器：Ubuntu Clang `18.1.3`，`/usr/bin/clang-18`（远端 `ENV.txt` 实读）；CMake `3.28.3`。
- 普通采集构建：`RelWithDebInfo`，C11，`-O2 -g -DNDEBUG`，无 LTO，无 sanitizer。
- 上游 vendor 库单独编译：`-Oz -g -fno-vectorize -fno-slp-vectorize`（`cmake/PlatformM2.cmake`）；
  M2 采集目标另加 `-DPLATFORM_M2_KYBER=1`，**不带** `BASELINE_ORDINARY_WORKLOAD`（因此类别数为
  `INPUT_CATEGORY_COUNT`，不是 ordinary 基准的 3 类）。
- sanitizer 产物（`build-sanitize/`）只作功能资格，**不得**用于计时或统计。

### 1.3 采集用普通 ELF 的 SHA-256

本轮 M2 采集用 collector 是 T2 已产出并**冻结**的新独立 ELF（`collector-v2-2e894561892a`），
它**不替换**、**不改动**现有 `build-ordinary/platform-m2/{unfixed,fixed}/measure` 两个只读原件。

| 角色 | 绝对路径 | SHA-256 |
|---|---|---|
| 采集（未修臂） | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector` | `b1e820e848d83cb334a967c64573c3c3355451e6e72778b45af96724e9c96b5d` |
| 采集（已修臂） | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector` | `c9cecdafb6bb855c44f08e52289baf2754fc6376fde0422ec004ec8945f4e9a8` |
| 只读原件（不采集） | `<Cry>/.../build-ordinary/platform-m2/unfixed/measure` | `dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7` |
| 只读原件（不采集） | `<Cry>/.../build-ordinary/platform-m2/fixed/measure` | `c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7` |

上表四条摘要均由 `plans` 于 2026-10-16 远端**独立实读复核**（附录 A 有命令与原始输出）；
两臂 collector 与两臂 `m2_dudect` 的绝对路径、sha256、ldd、调用边界与可直接复制的确切命令行，
另记于 `docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md`。**采集必须使用上表两条 collector**：
不得用只读原件冒充采集产物，也不得用已被取代的中间构建（见下方警告）。

> **中间构建警告（T2 实读，2026-10-16）**：同一 nonce 目录下曾有一版**补 `warmup_*` meta 字段之前**的
> 构建（unfixed `fd66e3a00d26d77da7b0d804a10f445a704662ebb7657a3b1c949f0f8905aa96`、
> fixed `bf402abfbc0c6fa64799c852ea02fa463be55689c81afe8854b8ef5cad0a845d`）。
> 该中间版本**已重建并被上表摘要取代**，**不得**用于采集；采集 ELF 的 sha256 必须等于上表值。

### 1.4 采集工具链（固定）

| 项 | 固定值（实读） |
|---|---|
| 频率/生命周期管理 | `tools/platform_control/controller.py`（唯一入口） |
| 统计电池 | `scripts/run_stats_battery.sh` |
| `platform_stats` | `/home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats`，SHA-256 `ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2` |
| RTLF | `/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R`，SHA-256 `50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e` |
| 在线 dudect 适配 | **已冻结**：`collector-v2-2e894561892a/build-ordinary/collector/{unfixed,fixed}/m2_dudect`；未修 `1c4e19866e7e1986f784d0819a14d993cc76ab5ebcc3ae636483cd9728103c1a`、已修 `ff92c5df271dc337c78e4b78311fa0e9b99cced59c1b754466e9dea52e038858`（`plans` 独立复核）。CLI：`m2_dudect --collect <新CSV> 20 31337 <pk.bin> <sk.bin>`；每批 10000、batch 0 为上游预热/分位批，**20 批 = 1 预热 + 19 检验批 = 200000 次**；默认阳性粘滞。**仅在绑核 + 锁频的在线运行里出结论**（未受控运行的环境漂移见 §4.2）；未执行即写 `blocked/not_run`，不得用离线回放冒充在线 |
| 主机 | `nss-m`，Linux `6.17.0-35-generic`，x86_64，AMD Ryzen 9 9950X 16-Core / 32 逻辑 CPU |

---

## 2. 类对

### 2.1 主类对（进入主检验）

**class0 = `message-zero`，class1 = `message-ones`**；效应量定义为 `mean(message-zero) − mean(message-ones)`，
双侧。两类是同一固定测试 key 下的两个显式选定消息的**合法 1088 字节密文**，各类重复同一密文；
它们正是 KyberSlash 除法热点在重加密压缩路径上所依赖的秘密消息形态（全 0 位 / 全 1 位）。

### 2.2 对照类对（**不进主检验**）

**class0 = `malformed-zero-tail`，class1 = `malformed-ff-tail`**（对象名由 T2 的
`COLLECTOR_CONTRACT.md` 定稿口径给出）。构造：合法 1088 字节密文，前 1056 字节逐字节取自
`message-zero` 基准密文，末尾 32 字节分别全部置 `0x00` / 全部置 `0xFF`（固定模式破坏尾部）。
两者前缀逐字节相同、只差尾部 32 字节，是**配对**的；长度仍是合法 1088，因此落进隐式拒绝路径，
**不缩短实际长度、不是长度字段破坏**（长度非法会在封装层先验拒绝，落不到完整解封装窗口）。

**它不进主检验的理由**：这一类对触发的是隐式拒绝/错误分支，其"秘密相关"来源与主类对
（重加密压缩路径的消息位依赖）**不同源**；把它纳入同一个 Holm 家族会用一个分支存在性/噪声主导的
对照项去污染一个专门检验秘密依赖的家族，使全族 α=0.05 的 FWER 解释失去意义。它只作
**族外稳健性/链路灵敏度检查**，单独 CSV、单独目录、单独报告。

### 2.3 版（臂）

两个独立普通 ELF：**未修** `a621b8d…` 与**已修** `272125f…`。两臂各自的类对均按 §2.1/§2.2 采集；
跨臂整体耗时差只作描述，不作泄漏证据。

---

## 3. 三次运行与预算

### 3.1 复制（replication）表

| run | 测试 seed | CPU | 变体顺序（合同的一部分） |
|---|---:|---:|---|
| `m2_r01` | 31337 | 2 | 未修 → 已修 |
| `m2_r02` | 424242 | 2 | 已修 → 未修 |
| `m2_r03` | 31337 | 6 | 未修 → 已修 |

- 顺序交替是预注册的一部分，不得因观察结果改序；六个主采集进程与六个对照采集进程**顺序执行**，
  禁止并行占用 CPU2/CPU6。
- run1 与 run3 同 seed、不同 CPU，用于区分"seed 相关"与"CPU 相关"；**不得**把两个 CPU 称作两台独立机器。

### 3.2 预算（每 run、每臂）

| 流 | 类 | 每次数 | 说明 |
|---|---|---:|---|
| 主类对 | `message-zero`、`message-ones` | 各类 **10000** | 进主检验 |
| 对照类对 | `malformed-zero-tail`、`malformed-ff-tail` | 各类 **10000** | 族外，独立 CSV |

- 每 run 每臂主类对 **20000** 次完整解封装；对照类对另 **20000** 次。
- 全轮主类对 **3 run × 2 臂 × 2 类 × 10000 = 120000** 次；对照类对同为 **120000** 次（族外）。
- **预热 100 次**：每个采集进程在计时循环前执行 100 次完整解封装（collector-v2 的显式
  `--warmup 100` 参数，默认即 100），预热样本**不进 CSV**、在窗口外，meta 记
  `warmup_decapsulations=100`、`warmup_attempted_calls=100`、`warmup_completed_calls=100`
  三个字段（资格脚本已断言这三项）。全轮预热 = 12 进程 × 100 = **1200** 次。
  预热字段缺失或不等于 100 即视为该 run 无效。
- **窗口只包一次完整 `mlkem_decapsulate`**：两个 `CLOCK_MONOTONIC` 纳秒读钟之间夹一次完整解封装，
  两侧 `atomic_signal_fence`；输入生成、分配、类别乱序、结果消费、日志与 I/O **全部在窗口外**。
- **全量保留长尾**：不做截尾、不删普通长尾、不扣读钟开销、不把 ns 换算成 CPU cycles。
  原始逐条 CSV 与原始顺序、时钟单位、类乱序种子全部保留。
- 输出 CSV 表头固定为 `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  单位 `ns`；已存在文件必须失败（`wx` 语义），拒绝覆盖。
- 单进程管理上限与整轮上限由主控在准入时按夹具实测设定；超时或资源错误即停止本轮、恢复配置并保留现场。

---

## 4. 统计

### 4.1 独立 Holm 家族与 m 的推导

- 家族 ID：`m2_end_to_end_full_decaps_v1`。
- 家族成员定义：**在一次 run 的一个臂内**，对主类对做一次双侧 Welch 大样本正态近似参数检验
  `H0: mean(message-zero) − mean(message-ones) = 0`。
- **m = 3 run × 2 臂 = 6**（6 个成员：r01-未修、r01-已修、r02-已修、r02-未修、r03-未修、r03-已修）。
- **α（全族）= 0.05**。Holm 逐步法：把 6 个原始 p 升序排列为 `p_(1)…p_(6)`，对第 k 个比较
  `p_(k) ≤ 0.05 / (6 − k + 1)`；首次不拒绝即停止后续拒绝。原始 p、秩次、阈值、调整值与逐项判决全部保存。
- 每项同时报告：两类原均值/方差/样本数、SE、Welch t、自由度、**95% 大样本正态近似 CI**。
  明确这是正态近似口径，**不是有限样本精确 Student-t**；CI 是单项描述区间，**不**冒称六项同时覆盖。
- 零方差、缺失 run、null p、p 下溢为 0 等异常原样保留，**不得**因此缩小家族数或按零 p 伪造通过。
- 六项全部保留，不按观察结果拆成每 run 的 m=2，也不择取最显著的 seed/CPU。

### 4.2 明确写在 Holm 家族之外

- **RTLF：α = 0.01，bootstrap 种子 2026101605，族外。** 每份主类对 CSV 各执行一次，
  使用固定上游脚本（§1.4 摘要）。其**二值结果不转换成连续 p、不进 Holm**；工具缺失或阻塞时
  按 `not_run`/明确状态保留原值，**不当阴性**。
- **online dudect：族外。** 入口为 `m2_dudect`（钉版上游 `dudect_main`，已交付并冻结），每臂一次、
  **固定 20 批**：每批 10000 次回调，**batch 0 是上游预热/分位批次、不计入 t 检验**，
  故 20 批 = 1 预热 + 19 检验批 = **200000 次**完整解封装；保留上游原裁剪/二阶辅助检验与
  `max|t| > 10` 阈值。**默认阳性粘滞**（跑满 20 批，符合本合同"无论是否提前遇到阳性都保留 20 批"），
  不使用 `--stop-on-positive`。**最大 t 不得转换成伪 p，不得进入 Holm**。
  命令：`m2_dudect --collect <新CSV> 20 31337 <pk.bin> <sk.bin>`（两臂各一次，独立 CSV）。
  未执行即写 `blocked/not_run`，不得用离线回放补签。
- **⚠️ dudect 结论只允许来自绑核 + 锁频的在线运行**：T2 的在**未绑核、未锁频**条件下的就绪运行出现
  `max|t| > 10`——4 次交替顺序诊断里 3 次阳性、**与变体顺序无关**，同期 `avg_mhz` 在 3105–3901 间漂移。
  该现象说明未受控环境下阈值会被环境漂移击穿，**不得引用这些未受控数字作为任一方向（阳性或阴性）
  的泄漏结论**；正式 online dudect 必须在 §7 的锁频控制器内、CPU2/6 绑核执行。
  这也是"未完成不补签"口径的一部分。
- 对照类对（§2.2）同样**不进 Holm**：它只做族外描述性检查与链路灵敏度说明；单独 CSV、单独输出目录，
  **不并入** `holm.csv`。

---

## 5. 条件微基准（`B06`，触发条件事先固定）

### 5.1 触发条件（**仅当**满足才触发）

仅当**完整解封装主类对在三次运行合并后仍不可区分**时才触发，操作化定义为**同时满足**：

1. 家族 `m2_end_to_end_full_decaps_v1` 的 6 个成员**全部未被拒绝**（Holm 无任何拒绝，且每项 95% CI 含 0）；
2. 以臂为单位把三次运行的主类对原值合并（不跨臂、不跨类）后，**两个臂的合并 Welch 检验也都不拒绝**。

条件 2 的两个检验**只作触发门**，不是家族成员、不作为任何证据，且必须写明它混合了两个 seed 与
两个 CPU、不满足独立同分布前提。行政/恢复失败或缺失 run **不能**触发补救采样，应停止并保留未完成状态。
本条件**不能**用于增加或替代端到端样本。

### 5.2 微基准合同（触发后）

- **只包除法热点**：窗口内只执行被定位层确认的除法热点（上游 `poly_tomsg` 的消息压缩除法），
  **不包**完整 decapsulate、不包其他函数、不择取更显著的函数。
- 使用与主采集相同的普通 Clang18 源码与编译选项、单调用 ns 窗口；分配/输入/消费/日志在窗口外；
  禁用 sleep、随机延迟、空转或秘密输出。若需新建微基准驱动，先完成其普通/sanitizer 资格与
  代码/ELF 摘要，未审入口不得采数。
- 预算与三次运行表（§3.1）一致，每类 10000、另 100 次预热。
- 微基准是**单独标记的探索族**（独立 Holm、α=0.05、RTLF 同 α=0.01），**不与端到端 p 合并**，
  不主张两族合起来仍是总体 α=0.05。

### 5.3 分层报告（硬要求）

结果必须分三层分别报告，**不得用微基准阳性冒充端到端阳性**：

1. **定位层**：静态/动态定位（源码秘密依赖、反汇编、`div/idiv` 对照、动态标记）的结论与范围；
2. **微基准层**：只包热点的观察与统计结论；
3. **完整调用层**：完整解封装主类对的观察与统计结论（含"未检出"）。

三层可以方向不一致；报告必须保留不一致，不得只报阳性层。

---

## 6. 停止、复测与失败归档

### 6.1 停止规则（任一命中即停止本轮，不进采数或立即中止）

- 本 PLAN 未提交，或提交后内容与执行清单不符；采集 ELF 的 sha256 与 §1.3 不符；
- 功能资格失败（公开 KAT、边界/长度/空指针、随机源失败、两臂等价）；
- 动态检查产物被当作计时产物；
- 远端路径越出 `/home/nss-marker/yhr/Cry` 物理边界，或发现符号链接越界；
- 频率/恢复合同未成立（§7 任一硬条件不满足）；
- 数据不完整（行数、类别数、表头、`time_unit`、meta 状态不符），或进程异常退出；
- 采集工具自身写频率/隔离，或另有任务占用 CPU2/CPU6；
- 出现密钥恢复、exploit、外部秘密、sleep/延迟伪阳性类操作。

### 6.2 复测规则

- **不得**因显著性或未显著而增样、追加 seed、补跑或挑选成功进程；不得看到结果后换类对、改顺序、改阈值。
- 复测只允许在"失败已归档 + 原因已定位 + PLAN 修订并重新提交"之后，**另立新目录**进行；
  修订版 PLAN 必须写清新的失败原因与新固定参数，不得改写旧结果。
- 复测数据不能与首轮数据合并成一个更大的家族来凑显著性。

### 6.3 失败归档规则

- 失败原件**先归档再重跑**：把该次运行的原始 CSV、meta、日志、控制/恢复日志按**原字节**
  复制到该运行目录下的 `failed/<run_id>/`，写 `MANIFEST`（来源路径、摘要、失败原因、失败时间）；
  归档完成后才允许启动新运行。
- 失败运行**不计入**家族成员数，也不从家族里"消失"：RESULT 必须列出已归档的失败尝试。
- 部分完成的数据一律标 `incomplete/failed`，**不得**当成功样本使用。

---

## 7. 频率与恢复（G05）

- 唯一串行任务：全程由 `tools/platform_control/controller.py run` 持有既有
  `Cry/partition-admin.lock` 与控制根 `collection.lock`；换 CPU、换控制根、`recover` 互斥。
- **boost = 0**（全局）；目标 singleton policy 的 **governor = performance、EPP = performance**、
  **min = max = 4300000 kHz**（CPU2 或 CPU6）。
- **taskset 亲和性**由控制器建立独立进程组并记录实际亲和性；worker 不得自建 session、fork 或 daemonize。
- **三次频率快照**：**进入前**、**运行中**、**退出后**各一次，保存全部可见 policy 的控制值与身份、
  全局快照与逐字段回读；运行中另有 20 次 50 ms 间隔的当前频率采样（均须在目标 ±2% 且跨度 ≤ 50000 kHz 才放行）。
- **`restore_match=yes` 才算有效**：`terminal.json` 成功需同时满足 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes`，且全局 active 指针消失。
  任一不满足即该 run 无效，按 §6.3 归档。
- 异常退出（worker 故障、超时、guardian 死亡）**必须恢复**原配置后才能继续；恢复失败则保留 active 阻断，
  由主控按独立 `recover` 入口处理，**不自动重跑**。
- 请求频率与可见配置匹配**不等于**逐调用恒频；不得把 4300000 kHz 写成物理恒频或误差界。
- 全部原件、缓存、临时目录、日志与分析只在 `/home/nss-marker/yhr/Cry` 物理边界内；worker 自身
  使用运行目录的 `worker/`、`tmp/`、`cache/`，不重设 HOME。

---

## 8. 执行入口（主控串行，固定形态）

主类对（collector-v2 确切 CLI，参数名以 `COLLECTOR_CONTRACT.md` §7 为准）：

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py run \
    --control-root <控制根> --run-name m2-r01-unfixed-main --cpu 2 --timeout-seconds <T> \
    --plan <控制根>/PLAN.md --plan-sha256 <冻结PLAN的SHA256> \
    -- /home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw <新目录>/m2_r01_unfixed.csv --meta <新目录>/m2_r01_unfixed.meta \
        --run-id m2_r01_unfixed \
        --public-key <fixtures>/pk.bin --secret-key <fixtures>/sk.bin
```

族外对照类对：同一 ELF，改 `--class malformed-zero-tail,malformed-ff-tail`、换**另一个**
`--raw`/`--meta`/`--run-id`（**绝不混入主 CSV**）。已修臂把路径中的 `unfixed` 换成 `fixed`；
run2 用 `--seed 424242`，run3 用 `--seed 31337` 且 CPU 换 6。
在线 dudect（族外，两臂各一次，仅锁频后执行，命令同形）：

```sh
    -- /home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_dudect \
        --collect <新目录>/m2_dudect_unfixed.csv 20 31337 <fixtures>/pk.bin <fixtures>/sk.bin
```

`--samples` 上限 20000/类；`--warmup` 默认 100；类对两次采集必须是**两个独立调用、两个独立 CSV**。

- 每个 (run, 臂, 类对) 一个**新** run-name、一个**新**输出目录；已存在文件必须失败。
- 统计（每份原 CSV 一个**新**输出目录）：

```sh
scripts/run_stats_battery.sh --input <原CSV> --format measure \
  --classes message-zero message-ones --output-dir <新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

- 主控另输出 `holm.csv`（假设 ID、原始 p、秩次、阈值、调整值、判决），**不改写**统计电池的单项结果。
- **对照类对**：同一份 `platform_stats` 电池**可以**直接吃对照 CSV——`scripts/platform_stats/stats_csv.c`
  的 measure 分支不调用 `parse_input_category`，而是把 `input_category` 字段与 `--classes` 两个字符串
  直接比较（不匹配的行只计入 `excluded_count`，不报错）。因此固定命令为：

```sh
scripts/run_stats_battery.sh --input <对照CSV> --format measure \
  --classes malformed-zero-tail malformed-ff-tail --output-dir <对照新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

  对照结果**只作族外描述**，**不得**并入 `holm.csv`，也不得与主类对合并成一个家族。
  仍必须满足电池的输入格式硬规则：表头逐字节等于
  `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n`、
  每行 6 个非空字段、`time_unit` 为 `ns`、`run_id`/`implementation` 全文件一致、每类 ≥2 样本。
  ⚠️ **另一路工具是 fail-closed 的**：`src/timing_statistics.c` 的 `load_measurement_set()`
  （analyze/audit 那一路）走 `parse_input_category`，只认历史 5 类，遇到 `malformed-*` 会整份拒绝。
  因此"能喂"**仅指** `platform_stats` 电池；不得把对照 CSV 喂给 analyze/audit 路。
- `<T>`、`--collect` 的确切参数名以 T2 冻结的 `COLLECTOR_CONTRACT.md` 为准；本 PLAN 提交后不得再改语义。

---

## 9. 三句结论模板（RESULT 必须逐字回答）

1. **定位**：本固定源码/编译器/产物在**定位层**是否显示秘密相关的除法/访存依赖，范围与证据是什么。
2. **统计**：本合同的 6 项主类对 Welch 检验与 Holm（α=0.05）**实际**给出什么（含未检出、含失败项），
   RTLF（α=0.01）与 online dudect 作为族外工具各给出什么。
3. **边界**：结论只覆盖本固定输入、本机、本预算与本产物；**不可区分 ≠ 恒时证明**，未检出既不证明
   恒时也不证明总体误报率为零；微基准阳性只属微基准层，不得上推为端到端阳性。

---

## 附录 A：ELF sha256 实读记录

实读时间：2026-10-16 02:0x–02:2x（CST），操作者 `plans`（task-7），**只读，未写入远端**。
本节含两段：(A) 只读原件基线；(B) **采集用 collector-v2 与 `m2_dudect` 的独立复核**（采集取此段）。

**(A) 只读原件基线（不用于采集）** —— 命令（原始，逐字）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry && sha256sum \
     platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/unfixed/measure \
     platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/fixed/measure'
```

原始输出（逐字）：

```text
dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7  platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/unfixed/measure
c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7  platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/fixed/measure
```

**(B) 采集用 collector-v2 与 `m2_dudect` 复核（`plans` 独立实读）** —— 命令（原始，逐字）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector \
   && sha256sum unfixed/m2_decaps_collector fixed/m2_decaps_collector unfixed/m2_dudect fixed/m2_dudect'
```

原始输出（逐字）：

```text
b1e820e848d83cb334a967c64573c3c3355451e6e72778b45af96724e9c96b5d  unfixed/m2_decaps_collector
c9cecdafb6bb855c44f08e52289baf2754fc6376fde0422ec004ec8945f4e9a8  fixed/m2_decaps_collector
1c4e19866e7e1986f784d0819a14d993cc76ab5ebcc3ae636483cd9728103c1a  unfixed/m2_dudect
ff92c5df271dc337c78e4b78311fa0e9b99cced59c1b754466e9dea52e038858  fixed/m2_dudect
```

补充实读（源码载体与工具）：

```sh
sha256sum /home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/source-upload.tar.gz
# 118aa44013b592a6e3265b23bc36978715bf6d96b705e48d8ef9e231805ee6b7
sha256sum /home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
# ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2
sha256sum /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
# 50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e
```

## 附录 B：待定项与非阻断记录

| 项 | 状态 | 处置 |
|---|---|---|
| 采集两臂 collector-v2 | **已冻结（`plans` 独立复核）** | 未修 `b1e820e8…`、已修 `c9cecdaf…`，路径见 §1.3 |
| 在线 dudect 两臂 `m2_dudect` | **已冻结（`plans` 独立复核）** | 未修 `1c4e1986…`、已修 `ff92c5df…`；20 批 = 200000 次、默认阳性粘滞；**仅在绑核 + 锁频运行出结论** |
| 未受控 dudect 就绪数字（`dudect-readiness/` 等） | **登记为环境漂移，不是泄漏结论** | 4 次交替诊断 3 次阳性、与变体无关、`avg_mhz` 3105–3901；任一方向都不得引用（§4.2） |
| 中间构建 `fd66e3a0…`/`bf402abf…` | **已被取代，不用于采集** | 见 §1.3 中间构建警告；原件与旧资格日志归档在该树 `superseded/`，**保留不删** |
| `<Cry>` | 书写约定 | `/home/nss-marker/yhr/Cry`，非阻断 |
| `<T>` | 待定 | 单进程管理上限（秒），主控准入时按实测设定 |

**本模块待填 ELF 占位符共 0 个**：采集两臂与 dudect 两臂摘要均已实读填实（附录 A 段 B）。
