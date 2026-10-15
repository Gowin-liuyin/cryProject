# 环境与产物范围

- 基线提交：`ac46e625c5c8e0db239f95b2464c9eaa6f55bf72`，main。
- 本机执行：macOS / ARM64；完整 uname 和 Java 版本位于 `local-qualification/`。
- 本机 JDK：Amazon Corretto `11.0.30`；最初资格使用 `--release 8`，最终跨环境
  CMake 使用 source/target 11，并再次执行本机资格。
- Linux 执行：nss-m / x86_64，系统 Java `21.0.12.1`；使用已装 `jdk.compiler`
  模块，无系统 javac 命令，启动器仅在自有 `run/tools/`。CMake 3.28.3。
- 上游 report：`4c74fb7e629b4d057b2d5d4accdb120d920774b7`，tree
  `507bba2ad89423354ffe4657a3ed102c3864b3c0`；工作区保持干净。
- 编译上游 25 个 Java 文件和独立 `MonaReplay.java`；使用快照自带三个 JAR。
- 固定 28 份源/JAR 字节摘要为 `scripts/platform_mona/upstream.sha256`；CMake 配置
  和每次回放都会校验。没有改动上游快照，无兼容补丁；只用 Java 子类关闭排版回调。
- 依赖许可记录：Commons Lang、ini4j 为 Apache-2.0，JSAP 声明 LGPL 未指定版本；
  Mona 本体未明确授权，不向本仓库提交其源码或 JAR。
- 原始输入来自既有 x86_64 Linux M1；本次两环境离线处理与当年的硬件采集分开。
- 源码、JAR、字节码、输入摘要与运行日志随各结果保存；未将 `build/` 称为证据。
- 成功 Linux 原件根为 `Cry/platform-mona-20261016-1de26030f145`；失败准备根保留
  `9739782d8827`、`91cff524d9c0`、`8a79566b085d` 三次。所有新文件均在各自 Cry 树内。
- 共享 SSH 由主控核验后使用，离线构建及回放以 CPU0/1 启动；结束无该根 Java
  子进程，后核对亲和性 `0-1`。没有关闭主控 socket。
- 完整原包及选择原字节副本核对通过，见 `archive-verification.json`；含上游程序
  的完整私有原件被 `.gitignore` 排除，只提交不含其源码/JAR的日志与结果。
- 无调频、MSR、隔离、锁频采数、系统包安装或 Docker 执行。
