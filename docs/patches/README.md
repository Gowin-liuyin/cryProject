# 补丁目录

本目录只放**可复算的补丁文件本体**；补丁的来源、适用对象与验证结果在各证据目录里。

| 补丁 | 性质 | 适用对象 | 用法 |
|---|---|---|---|
| `liboqs-982c762.patch` | **上游官方补丁**，逐字节取自 `https://github.com/open-quantum-safe/liboqs/commit/982c762c242ef549c914891b47bf6e0ed6321f91.patch` | liboqs 0.10.0 的 `src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/`（及同批 kyber 变体） | `sh tools/fetch_all_vendors.sh`：把 `vendor/liboqs-0.10.0/` 复制成 `vendor/liboqs-0.10.0-982c762/` 后用 `patch -p1` 应用；脚本同时校验补丁 SHA-256 与三处效果标记 |
| `m3-mem-lut-toggle.patch` | 本项目自写，**人工构造校准** | `vendor/mlkem-native/mlkem/src/compress.c` | 制造 M3 的秘密下标查表阳性臂 |
| `message-branch.patch` | 本项目自写，**人工构造校准** | 同上 | 制造数据相关分支对照 |
| `message-constant-time.patch` | 本项目自写，**人工构造校准** | 同上 | 掩码选择（无分支）对照 |
| `message-encoder-macro.patch` | 本项目自写，**人工构造校准** | 同上 | 消息编码器宏化对照 |
| `message-value-barrier.patch` | 本项目自写，**人工构造校准** | 同上 | 值屏障对照 |
| `diagnostic-stages.patch` | 本项目自写，诊断用 | `mlkem/src/indcpa.c` | 诊断阶段插桩，不属于交付产物 |

## 纪律

- **上游快照不改名、不修改**：`vendor/` 下的树保持上游原样，修复一律通过副本 + 补丁实现
  （`vendor/liboqs-0.10.0-982c762/` 是 `vendor/liboqs-0.10.0/` 的副本，不动原树）。
- **官方补丁与自写补丁分开登记**：`liboqs-982c762.patch` 是上游原件，本仓库只保存副本并
  记录 SHA-256，不改一个字节；其余六个是本项目为人工构造校准写的补丁，**不是**上游修复，
  也不能当作真实实现的修复点。
- **人工机制回归须明示**：凡使用后五个补丁的结论都标「人工构造校准」，只用于检验检测器
  能否识别目标机制，不计为新的真实 CVE。
