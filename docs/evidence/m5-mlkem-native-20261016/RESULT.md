# M5 mlkem-native 前置接线

1. **定位**：固定上游提交 `b3ba7b32773e657dd37f6f87bce82528459ad8a4` 的完整库目录与许可证
   共 126 文件复核相同；复用 `reference_measure → mlkem_decapsulate → baseline_native_dec`，
   实际 macOS/ARM 产物保留这条调用链。未运行 ctgrind 或 varlat，不报告动态定位阴性。
2. **统计**：本轮未采时间 CSV，也未运行 CI、Holm、RTLF 或 dudect；只有普通/ASan+UBSan
   参考功能资格各 5/5 与系统随机源往返通过。尚不能声称「全套工具不误报」。
3. **边界**：无密钥恢复；功能正确、有限输入不可区分、恒时证明是不同声明；本轮只验证
   Apple Clang 21/macOS arm64 便携 C 路径，不代替 nss-marker Linux x86_64 证据。

## 最小接线

原有参考适配已经满足可调用解封装，未新增内核、计时器、随机源或 C 适配。
`cmake/PlatformM5.cmake` 提供 `platform_m5_mlkem` 库别名、`platform_m5` CLI 构建目标、
`platform_m5_measure` 测量程序构建目标及 `platform_m5_check` 功能资格目标。
其中 measure 目标仅在 `A113_ARCHIVED_CASE_ONLY=OFF` 时存在，check 需 `BUILD_TESTING=ON`。
根 CMake 已由主控统一 include；下列 reference 命令与追加的三个平台聚合目标均已实际完成。

```sh
cmake -S . -B build/platform-s6/ordinary -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/platform-s6/ordinary --target check-reference reference_measure --parallel 4
cmake -S . -B build/platform-s6/sanitize -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/platform-s6/sanitize --target check-reference --parallel 4
build/platform-s6/ordinary/reference/baseline selftest
cmake -S . -B build/platform-s6/ordinary -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/platform-s6/ordinary --target platform_m5 platform_m5_measure platform_m5_check --parallel 4
```

已执行的五项分别为 `reference_kat`、`reference_random_failure`、`reference_cli`、
`reference_vector_parser`、`vector_integrity`。KAT 使用已有独立 NIST ACVP 固定向量，覆盖
密钥生成、封装、解封装和接口边界，包含隐式拒绝；没有以自产预期答案替代。

本次 `cmake-format 0.6.13 --check cmake/PlatformM5.cmake` 与现有 `format-check` 均通过。
主控接线后的三聚合目标全部通过，其中 `platform_m5_check` 再次执行参考资格 5/5。
普通测量程序的链接行只链接 `reference/libmlkem.a`，未链接 liboqs 或 patched 变体；
源码计时窗口围住完整 `mlkem_decapsulate`，不把 CLI 自检当作统计采集。

## 证据入口

- `PLAN.md`：本轮范围与不采数边界。
- `upstream-commit.json`、`snapshot-verification.json`、`snapshot-SHA256SUMS`：上游身份和 126 文件核对。
- `configure-*.log`、`build-*.log`：普通/动态构建与各 5/5 资格。
- `version.txt`、`selftest.txt`：实际 CLI 与系统随机源往返结果。
- `measure-link.txt`、`reference-compile-flags.txt`、`measure-symbols.txt`、`*-disasm.txt`：链接和调用链。
- `binary-SHA256SUMS`、`*-build-identity.h.txt`：本地实际产物摘要与构建时共享工作区身份。
- `configure-platform.log`、`build-platform.log`、`platform-binary-SHA256SUMS`：统一入口后三聚合目标验证；
  该次普通二进制重链，初次身份/摘要记录保持，新增记录单独绑定。
- `ENV.md`：本轮实际环境及后续原生项草案。

统一 include 与三聚合目标验证已完成。下一步冻结独立 M5 原生计划，再按单一锁频采数任务
规则执行定位与统计。M5 的正式阴性对照验收仍未完成。
