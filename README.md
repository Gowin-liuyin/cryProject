# A1-13：ML-KEM-768 C 时间侧信道实验基线

本仓库交付第一阶段单机软件基线：FIPS 203 口径的参考功能、明确标注的人工时序缺陷变体、
可复现测试输入、命令行和 C 内部逐次计时。没有扩展统计检测平台或密钥恢复系统。

## 构建与检查

需要 CMake ≥ 3.21、C11 编译器（Clang/GCC）、Make 或 Ninja、Git、patch、awk、shasum。
普通构建离线完成；重新转换已保存的 NIST JSON 才需要 jq。
Linux 可安装 `build-essential cmake git patch perl`，使用 Ninja 时另装 ninja-build。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel
ctest --preset baseline

cmake --preset sanitize
cmake --build --preset sanitize --parallel
ctest --preset sanitize
```

默认 RelWithDebInfo（本机 `-O2 -g -DNDEBUG`）、C11、严格警告、便携 C 后端，无 LTO。
构建目录为 build/cmake；sanitizer 使用独立 build/cmake-sanitize，产生的时间不用作性能证据。
所有构建和测试规则只在 CMake 中维护，`make` / `make test` / `make sanitize` 仅兼容转发。
原 Make 构建产物仍在原目录，不会自动删除或作为 CMake 构建复用。

也可以不用 preset，例如 Ninja、指定编译器或关闭测试程序：

```sh
cmake -S . -B build/ninja -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/ninja --parallel
ctest --test-dir build/ninja --output-on-failure
cmake --build build/ninja --target reference   # 只构建参考版 CLI 和采集程序
cmake --build build/ninja --target vulnerable  # 只构建缺陷版 CLI 和采集程序
```

`-DBUILD_TESTING=OFF` 关闭测试程序及 CTest 注册；`-DBASELINE_SANITIZERS=ON` 开启 ASan/UBSan。
多配置生成器用 `--config Debug` 构建、`ctest -C Debug` 测试，程序位于构建目录的 Debug/ 下。
禁止源码内构建。变更源码、头文件或缺陷补丁会触发相应重建；未变的构建身份不触发重复编译。
准确编译命令见构建目录的 compile_commands.json（Make/Ninja），运行元数据包含其摘要及配置。

## 运行和生成输入

```sh
build/cmake/reference/baseline version
build/cmake/reference/baseline selftest
build/cmake/vulnerable/baseline demo
mkdir -p runs/example
build/cmake/reference/baseline generate-test bit-flipped 42 runs/example/input.bin
build/cmake/vulnerable/baseline decapsulate-test 42 runs/example/input.bin
```

selftest/demo 使用系统安全随机源运行完整 keygen/encaps/decaps，不显示秘密；
完整 NIST 已知答案和边界检查用 `ctest --preset baseline`。
`generate-test` 支持 `valid`、`bit-flipped`、`random`、`message-zero`、`message-ones`。
两个 test 命令显式使用相同的公开种子重建测试密钥；输出文件只有 1088 字节密文。
测试种子不用于真实秘密，程序不打印私钥、共享密钥或内部重加密验证标志。
现有文件不覆盖。成功返回 0，公开命令参数错误返回 2，运行/文件错误返回 1。
正确长度无效密文仍完成隐式拒绝；不会以额外状态暴露内部验证结果。

## 原始计时

```sh
build/cmake/reference/measure example-reference 42 1000 runs/example/reference.csv runs/example/reference.meta
build/cmake/vulnerable/measure example-vulnerable 42 1000 runs/example/vulnerable.csv runs/example/vulnerable.meta
```

每版输出 5 类各 1000 条，总计 5000 条原始记录。所有密文预先生成，类别顺序可复现随机化；
C 内部 CLOCK_MONOTONIC 计时完整解封装，单位 ns。保存普通长尾，不做自动统计结论。
元数据绑定实际二进制 SHA3-256、源码提交/改动摘要、编译选项及实际环境。
详细边界见 [计时说明](docs/timing.md)。输出路径必须不存在。

## 来源、缺陷和验证状态

参考源码为 mlkem-native `b3ba7b32773e657dd37f6f87bce82528459ad8a4`，
参数 ML-KEM-768（公钥 1184、私钥 2400、密文 1088、共享密钥 32 字节）。
vendor 保留原始快照及许可证；[来源](docs/sources.md) 包含标准与外部案例链接。
人工回归仅替换消息编码 `mlk_poly_frommsg`：解封装重加密时按秘密相关消息位分支。
为在实际编译器下保留该机制，回归编码函数单独禁用优化；不是原样复现历史 clangover。
重加密验证、隐式拒绝和密码输出保持，详见 [补丁及机制](docs/defect.md)。
上游的证明或认证不自动覆盖本项目改动；参考版也不被宣称绝对无泄露。

本次真实平台为 Apple M5 / ARM64 macOS、Apple Clang 21，已经执行：

- 两版各 80 组 NIST 检查：25 keygen、25 encaps、10 decaps、20 密钥校验；解封装含 5 组隐式拒绝。
- 64 个固定种子 × 3 类密文的差分检查、公开长度/空指针边界、随机源失败传播和恢复。
- 两版 CLI、五类输入复现、CSV 行数/单位/类别顺序、干净构建及 ASan/UBSan。
- ARM64 实际编码分支确认与原始时序采集，最终证据见 [验证记录](docs/validation.md)。

**已确认目标机制并采集原始数据，时间差异尚未正式统计确认。**
未作“已观察显著差异”或“参考版无泄露”的结论。真实 x86_64 Linux、GCC 分支、
固定核心/频率下的正式测量仍待执行；没有将交叉编译或模拟器冒充目标实测。

后续检测读取 CSV 和运行元数据；后续防护从独立编码补丁入手，先保持 KAT/差分测试，
再检查修复产物和重新采样。本阶段不实现自适应输入、完整统计框架或最终防护。

## 文件职责

`src/` 是封装、系统随机源、输入、CLI 和计时；`include/` 是少量接口；
`tests/` 保存 C 测试和原始 NIST 向量；`docs/` 保存机制、补丁和实测证据；
`vendor/` 是未经修改的第三方快照；`tools/build_identity.sh` 仅生成构建追溯信息。
普通封装接口接受精确长度且要求调用方提供互不重叠的有效缓冲区。
