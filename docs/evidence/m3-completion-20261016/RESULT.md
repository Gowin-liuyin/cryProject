# M3 完整解封装人工 LUT 结果

1. **定位**：真实 nss-m/x86_64、Clang18.1.3 的完整 ML-KEM 解封装重加密路径中，
   人工 on 版秘密标记探针为 1280 errors/2 contexts（exit97），均落在 `compress.c:714`
   的秘密下标 LUT load；off 为 0/0（exit0）。两版 defined 对照也均 0/0。
2. **统计**：本路没有运行 measure、CI/Welch、Holm、RTLF 或 dudect；
   `STATISTICAL_PLAN.md` 已准备，必须由主控提交冻结后才可锁频采数，不填端到端阳性/阴性。
3. **边界**：这是人工访存校准，不是上游 CVE、攻击或密钥恢复。定位阳性不等于已有稳定物理时差；
   off 有限调用不报警不等于恒时证明。Microwalk 因 Pin/.NET 缺失与 Docker 存储越界而按计划降级。

## 实现与资格

`vendor/mlkem-native` 原件只读。两版在构建目录各自复制固定库，应用单独人工补丁，
构建独立库及 `platform-m3/{on,off}/{baseline,measure}`。接口检查、重加密比较、
隐式拒绝和系统随机源路径复用原实现，密码输出不改。

本机 macOS/ARM 与真实 Linux x86_64 的普通/ASan+UBSan两配置，均各 6/6：

| 检查 | 覆盖 |
|---|---|
| on/off 两项 NIST KAT 与接口边界 | 复用独立 ACVP 固定向量；覆盖长度、空指针及隐式拒绝 |
| on/off 两项随机源失败 | 资源限制下失败传播与恢复后的系统随机源往返 |
| 三版完整输出等价 | 64 公开种子×5类，reference/on/off 的完整公钥、公开测试私钥、密文和共享值逐字相同 |
| patch 严格 dry-run | 新 overlay，`patch --dry-run --fuzz=0` 通过 |

完整转录比较是字节比较，未以相等哈希替代；专用程序仅生成公开固定种子材料，
转录只进入构建测试目录，不接收实际密钥或成为产品秘密输出。bit-flipped/random
两类另检查 `J(z||c)`，独立正确性依据仍是 NIST KAT。

原生动态探针每版以固定公开种子完整执行五类解封装；没有直接调用热点替代整段路径。
原始 backtrace 是 `baseline_native_dec → baseline_native_indcpa_enc → baseline_native_poly_frommsg`；
优化中消息编码被内联，实际两个报警 PC 的静态偏移为 `0x5CED`、`0x5D15`，
均为 `movzwl (%r8,%rcx,1),...` 一类秘密索引 load。off 不含人工表符号。

## 复核入口

- `PLAN.md` / `STATISTICAL_PLAN.md`：本轮功能定位范围与尚未执行的统计草案。
- `source-upload.json`、`source-SHA256SUMS`：真实上传快照与未提交状态。
- `build-{ordinary,sanitize}.log`：本机各 6/6，`patch-*.log` 是应用与严格 dry-run。
- `native-8b6f2d91/`：原生环境、四组 Memcheck、完整 measure/probe 反汇编与结束核对。
  **更正**：本机两配置的 6/6 原始行其实在 `build-{ordinary,sanitize}.log` 第 68–80 行，
  该目录里没有独立的 ctest 日志；逐测试名与行号见 [TESTS.md](TESTS.md)。原生采数树的 6/6 见
  [LOCATE_RESULT.md](LOCATE_RESULT.md)（原始输出在 `locate-v2/`）。原文其余部分未改。
- `native-probe-identity.txt`、`native-lut-load-excerpt.txt`：同 ELF 摘要、源码行及 load 定位。
- `native-build-identity.txt`、`native-compile_commands.json`：原生真实编译输入与选项。
- `ENV.md`、`NOTES.md`：完整原件位置、全归档摘要、工具降级及有限结论。

自有 C/CMake格式、shell语法和 diff 检查通过；未重跑旧全仓库实验，未改 M1 vendor 或封存结论。
未执行采数、调频、频率恢复或 CPU 独占步骤，不把 restore_match 填 yes。

---

## 本轮锁频端到端结果（2026-10-16，控制器 `a3c9ca1`）

采数树：`Cry/platform-m3-locate-20261016-4b102a339cc8`（与定位复验同树）。
两臂 on `a371ed08…` / off `8daaea28…`；三次运行 seed 31337-CPU2、424242-CPU2、31337-CPU6；
每类 10000 次、预热 100。12 次控制器运行全部 `restore_match=yes`。

**1. 定位**：人工 LUT 开臂在 Memcheck 报 **1280 errors / 2 contexts**（`poly_frommsg` 处），
关臂 0/0；Microwalk 源码自建在开臂把 `poly_frommsg+30/+59` 的 MI 报到 **1.922 bits（全场最高）**，
关臂同函数 0.722 bits，两处正是 `platform_m3_message_bit_table` 的两次 `movzwl`，
与 ctgrind 报点同源。这是**人工构造校准**，不是上游 CVE。

**2. 统计**：家族 `m3_lut_arm_end_to_end_v1`，**m = 3 次运行 × 2 臂 = 6**，α 全族 0.05。
主类对在臂内（message-zero vs message-ones）。六项原始 p = 0.189/0.268/0.315（开臂）、
0.375/0.458/0.480（关臂），**Holm 拒绝数 0**；合并 Δ = −0.73 ns，95% CI [−5.56, +4.10]（含 0），I² = 12.5%。
按臂描述性合并：开臂 −0.62 [−7.78, +6.53]、关臂 −0.83 [−7.38, +5.72]，两臂都不含 0 之外的结论。
跨臂 on/off 对比**不进 Holm**（含二进制级常数偏移，不作秘密相关泄漏主证据）。
族外对照类对（`bit-flipped` vs `random`）六项 p = 0.462/0.687/0.587/0.735/0.684/0.162，无一致方向。
族外 online dudect 六次 max|t| = 1.93/2.24、3.41/3.37、2.81/3.03（on/off），状态 `state=1`（预算内无证据）。
**该入口的两条如实限制**：(a) 它是 M5 系 dudect 在本树重建的产物，实现名守卫按最小改动放宽到
`platform-m3-lut-on/off`（原件 sha256 `8beb2994…`、改后 `67eb4dca…`，两臂 ELF
`8ae8979f…`/`73a2b042…`）；(b) 该版本**不支持 `--raw`，不产出逐样本 CSV**，
只输出每批 `max t` 与最终状态行，原始 stdout 保存在各 run 的 `controller/worker.stdout`。
因此 M3 的在线 dudect **没有逐样本原件**，这一点按事实登记，不用离线回放冒充在线。
逐样本在线 dudect 需要重新导出源码并重建，本轮未做。

**3. 边界**：`measure` 的密文长度在 API 层固定（ML-KEM-768 为 1088 字节），
接口层无法表达"截断"，因此对照条件取内容被破坏/随机的密文，且一律族外。
端到端**未检出**与定位层阳性并存，本页不把定位阳性写成端到端阳性，
也不把"未检出"写成恒时证明。结论限定本机 x86_64、该夹具、该类对与该预算。
