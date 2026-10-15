# S3：Valgrind varlat 工具构建计划

冻结日期：2026-10-16（Asia/Shanghai）。本计划只构建并验证动态定位工具，不采集时序样本，不运行密钥恢复或 KyberSlash exploit demo。

## 输入与来源

- Valgrind 3.25.1 官方发行包：<https://sourceware.org/pub/valgrind/valgrind-3.25.1.tar.bz2>。下载后固定 SHA-256；上游源码和许可证保持原样。
- `valgrind-try-patch-20250805.txt`：<https://kyberslash.cr.yp.to/valgrind-try-patch-20250805.txt>，SHA-256 `6c0a69ef5372b335edc48430520352ec5844d2bafb16e7ef3688d2b3f8fe00ff`。
- `valgrind-varlat-patch-20250805.txt`：<https://kyberslash.cr.yp.to/valgrind-varlat-patch-20250805.txt>，SHA-256 `7e6518012a3caee69c5665c3a4c7f6419e290d4f1c9ec5a92fac14996a7d7922`。

两份补丁原件保存在 `third_party/valgrind-varlat/patches/`，证据目录另存原样副本。只在独立 Valgrind 工具树应用补丁；先 `patch --dry-run`，失败则保留日志，不手改补丁伪装原版。

## 执行边界

本机是 macOS/ARM；这里只做下载、摘要、解包、补丁及路径审查。实际工具构建和运行限定在 `nss-marker@10.144.144.5` 的新根 `/home/nss-marker/yhr/Cry/platform-s3-20261016-<nonce>` 内；先验证 SSH 主机密钥与真实 `readlink -f`。使用树内 `tmp/`、`cache/`、日志、源码、构建和安装目录，导出 `TMPDIR`、`TMP`、`TEMP`、`XDG_CACHE_HOME`，不重设 `HOME`。

先审查 configure、构建脚本与运行路径。只构建工具并执行 `--help` 和明确选择的工具校准，不运行包含显式 `/tmp` 路径的上游测试套件。实际工具运行使用 `--command-line-only=yes --vgdb=no` 和树内 `--log-file` / `--vgdb-prefix`。不使用 sudo、不更改主机频率或隔离配置，不绑定 CPU2/CPU6，编译并发上限 `make -j4`。

## 成功条件

1. 固定发行包和补丁摘要，完整记录补丁应用日志。
2. 在真实 x86_64 Linux 构建，保留环境、configure、make/install 日志和 ELF 摘要。
3. `valgrind --tool=memcheck --help` 显示 `--variable-latency-errors=no|yes`。
4. 如执行最小校准，应由显式秘密标记的除法触发 `Variable-latency instruction operand`，并保留公开输入对照；此结果只证明工具接通，不代替 M2 未修/已修定位结果。

SSH 认证、补丁不兼容或构建失败均按实际阻塞记录，不报告未执行成功。M1 vendor 和封存证据只读；不修改根 CMake，不 commit/stage，不 push。dudect 不进入 Holm 家族。本路不执行锁频；后续采数仍须先有 PLAN，boost 关、performance、约 4.30 GHz、taskset、进出 restore_match、退出恢复。
