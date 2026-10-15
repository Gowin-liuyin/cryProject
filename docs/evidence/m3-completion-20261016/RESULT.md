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
- `native-8b6f2d91/`：原生环境、各 6/6、四组 Memcheck、完整 measure/probe 反汇编与结束核对。
- `native-probe-identity.txt`、`native-lut-load-excerpt.txt`：同 ELF 摘要、源码行及 load 定位。
- `native-build-identity.txt`、`native-compile_commands.json`：原生真实编译输入与选项。
- `ENV.md`、`NOTES.md`：完整原件位置、全归档摘要、工具降级及有限结论。

自有 C/CMake格式、shell语法和 diff 检查通过；未重跑旧全仓库实验，未改 M1 vendor 或封存结论。
未执行采数、调频、频率恢复或 CPU 独占步骤，不把 restore_match 填 yes。
