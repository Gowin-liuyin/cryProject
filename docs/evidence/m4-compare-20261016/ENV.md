# M4 软件资格与定位环境

- 日期：2026-10-16。实现准备时主仓库 `main`，观察到 HEAD `193404792accdafc8dc36a2baec0279ff2e33079`；本路文件当时未提交，原始字节以 `local-source-sha256.txt`、Linux `source-sha256.txt` 和上传归档为准。
- 本机：macOS / Darwin 25.6.0，ARM64；Apple clang 21.0.0，CMake 4.3.2。
- 本机普通：`build/platform-s8/ordinary`，C11，`-O2 -g -DNDEBUG -arch arm64`，严格 warning 且 `-Werror`；未启用 poison、sanitizer 或 LTO。
- 本机动态：`build/platform-s8/sanitize`，Debug/C11，`-g -fsanitize=address,undefined -fno-omit-frame-pointer`，与普通产物隔离。
- Linux：`nss-m`，Linux `6.17.0-35-generic`，x86_64；GCC 13.3.0、CMake 3.28.3、系统 Valgrind 3.22.0。仅软件资格与一次 poison 定位，不是定时采样。
- Linux 新物理工作根：`/home/nss-marker/yhr/Cry/platform-s8-20261016-250f424b`。`source/` 为固定本路快照；`build-poison/` 为 RelWithDebInfo/C11、`M4_ENABLE_CTGRIND=ON`；实际选项与 ELF 在完整归档内。
- Linux `TMPDIR`、`TMP`、`TEMP` 指向该树 `tmp/`；`XDG_CACHE_HOME` 指向 `cache/`，`DOCKER_CONFIG` 指向 `docker/`。源码执行路径没有硬编码临时目录。树内未发现符号链接。
- 未调用密码算法、root、MSR、频率或隔离管理；未指定 CPU 亲和性、未占用 CPU2/CPU6 采数锁，没有 `restore_match` 或恒频声明。
- 结束检查：记录的 helper/Valgrind PID `186928`、`187120`、`187130` 均不存在；未关闭共享 SSH 控制连接。
- Linux 定位 ELF SHA-256：vulnerable `28e39ae960f14f7eb3b7456eca610bea3d649dae86efdee3b672bf2d565dd911`；ct `6fb0c61b854de165948096d22a674172e0719e02d7b5f01e4e53d2c8655bd92a`。
- 本机 ELF/Mach-O 摘要见 `local-binaries-sha256.txt`（本机实际是 Mach-O）；Linux 全部四 ELF 摘要见 `linux-run-250f424b/binaries-sha256.txt`。函数反汇编见同目录 `disasm-*.txt`。

Linux 原件在远端保留。`complete.tar.gz` 是首次归档，tar 因在根目录内创建归档报告
`.: file changed as we read it`；原包保留，不作最终完整性依据。随后使用显式成员列表新建
`complete-v2.tar.gz`，没有该警告，SHA-256 为
`7dfb547dd71edacaf9e485d7adc6d5535b2ecc703fc73889c590542a21ae78e4`。
本地独立读取 v2 包确认 10 个夹具源文件逐字节等于当前本路文件，可读日志副本逐字节相等，
四个归档 ELF 摘要均相符，见 `local-archive-verification.txt`。`build/` 中本机产物不作为远端证据。

格式：Apple clang-format 21 `--dry-run --Werror` 及 cmakelang 0.6.13 `cmake-format --check` 均通过。
