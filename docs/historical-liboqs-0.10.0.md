# 历史主阳性：liboqs 0.10.0（GHSA-f2v9-5498-2vpp / clangover）

## 角色分工（本仓库）

| 角色 | 对象 | 说明 |
|---|---|---|
| **主阳性** | Open Quantum Safe [liboqs 0.10.0](https://github.com/open-quantum-safe/liboqs/releases/tag/0.10.0) | 真实第三方历史快照；在公告条件下 `poly_frommsg` 可被 Clang 编出秘密相关分支 |
| **附录阴性** | 当前 `vendor/mlkem-native`（提交见 [sources.md](sources.md)） | 前沿恒时实现；本地时序不显著时如实记为阴性，不假装打穿 |
| **开发夹具** | 人工 `message-branch` / `vulnerable`–`hardened` | 仅用于开发与回归调试；正文不以「对成熟实现的新漏洞发现」表述 |

固定身份见 [`vendor/liboqs-0.10.0.PIN.md`](../vendor/liboqs-0.10.0.PIN.md)。提取树由 `tools/fetch_liboqs_0.10.0.sh` 下载并校验 SHA-256，路径 `vendor/liboqs-0.10.0/`（gitignore，不入库）。

## 算法与语义边界

- 接入算法：`ML-KEM-768-ipd`（liboqs 0.10.0 随 FIPS 203 **初始公开草案** 引入的实现）。
- 公开尺寸与本仓库 `include/mlkem.h` 一致（ek 1184 / dk 2400 / ct 1088 / ss 32），因此可复用现有 `baseline` / `measure` CLI 与计时 CSV 格式。
- **不得**把该历史 IPD 快照写成最终 FIPS 203 认证模块；正式 FIPS 203 正确性主线仍是 mlkem-native `reference`。
- 本变体**不做**与 `tests/vectors/mlkem768.txt`（最终稿向量）的 KAT 绑定；默认只提供系统随机 roundtrip selftest。
- 本轮目标是解封装**计时检测链路**可接上，不是密钥恢复 exploit。

## 公告复现条件（时序阳性）

依据 [GHSA-f2v9-5498-2vpp](https://github.com/open-quantum-safe/liboqs/security/advisories/GHSA-f2v9-5498-2vpp) / [clangover](https://github.com/antoonpurnal/clangover)：

- **ISA**：x86 / x86_64（本仓库 Apple Silicon 本机**不能**冒充该实测）
- **编译器**：Clang 15–18（含文档所列版本区间）
- **选项**（任一即可触发分支的常见集合）：`-Os`；`-O1`；`-O2 -fno-vectorize`；`-O3 -fno-vectorize`
- **后端**：必须落到 **portable C `*_ref`** 的 `poly_frommsg`；不要用 AVX2 后端当阳性对象

修复上游：liboqs **0.10.1+**（提交 `982c762c242ef549c914891b47bf6e0ed6321f91`）。阳性实验钉在 **0.10.0**，不要「顺手升级」。

## 本机（macOS arm64）与远程 x86 计划

当前开发机：`arm64-apple-darwin`，Apple Clang 21。此环境可以：

1. `tools/fetch_liboqs_0.10.0.sh`
2. 配置并构建 `historical` 变体，跑 `historical_selftest` / `historical/baseline selftest`
3. 验证 CLI 与封装是否接上

此环境**不可以**：

- 声称已复现 GHSA/clangover 时序分支或密钥恢复
- 把 arm64 计时当作主阳性证据

**正式时序阳性**放到已授权的 x86_64 Linux（优先可锁频或已有证据流程的裸金属 `nss-marker@10.144.144.5` 工作根 `/home/nss-marker/yhr/Cry`；KVM `cryproject-native-x86` 可作功能/接入预检，但客户机无 cpufreq 锁）。远程步骤草案：

```bash
# 在仓库根（已 fetch vendor）
cmake -S . -B build/historical-clangover -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_C_COMPILER=clang \
  -DBUILD_TESTING=ON \
  -DBASELINE_SANITIZERS=OFF \
  -DA113_ARCHIVED_CASE_ONLY=OFF \
  -DBASELINE_ENABLE_LIBOQS010=ON \
  -DLIBOQS010_C_FLAGS="-Os -fno-vectorize"
cmake --build build/historical-clangover --target historical -j"$(nproc)"
ctest --test-dir build/historical-clangover -L historical --output-on-failure
# 随后用 historical/measure 走与现有 analyze 相同的 CSV 协议；未跑通前不写阳性结论
```

CMake preset 名：`historical-clangover`（见根目录 `CMakePresets.json`）。在 Apple Silicon 上该 preset 仅用于**接入与语法检查**；证据目录需单独标注 `arch=arm64` 且不得升格为主阳性。

`cmake/Liboqs010Historical.cmake` 额外关闭 AVX2 指令与 `ML-KEM-768-ipd` 的 AVX2 后端，并把 `LIBOQS010_C_FLAGS` 写入各配置专用的 `CMAKE_C_FLAGS_*`。只设 `OQS_DIST_BUILD=OFF` 时，具备 AVX2 的 x86_64 仍会在运行时走到 AVX2；`RelWithDebInfo` 自带的 `-O2` 也会排在 `CMAKE_C_FLAGS` 后面，盖掉 `-Os`。阳性对象必须是 portable C `*_ref` 的 `poly_frommsg`。

## 构建命令（默认功能接入）

```bash
./tools/fetch_liboqs_0.10.0.sh
cmake -S . -B build/historical -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_TESTING=ON \
  -DBASELINE_ENABLE_LIBOQS010=ON \
  -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/historical --target historical -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
ctest --test-dir build/historical -L historical --output-on-failure
./build/historical/historical/baseline selftest
```

未设置 `BASELINE_ENABLE_LIBOQS010=ON` 时，原有 `reference` / `vulnerable` / `hardened` / `deployable` 行为不变。

## 与人工夹具的关系

- `docs/patches/message-branch.patch` 等仍保留，供 mlkem-native 变体使用。
- 报告正文应优先叙述 **liboqs 0.10.0 历史阳性**；人工分支降为「检测器开发夹具」。
- 在历史树上尚未完成「可区分 → 定位 → 套修复复测」之前，不把 r07 人工闭环改写成第三方漏洞发现。

## 构建身份

`tools/build_identity.sh` 只哈希 `vendor/mlkem-native` 与 `vendor/` 顶层 PIN 文件；完整 liboqs 树以 PIN 中的 archive SHA-256 为准，避免每次构建扫描数千上游文件。
