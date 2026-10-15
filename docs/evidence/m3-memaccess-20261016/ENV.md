# M3 本轮环境

日期按用户时区为 2026-10-16。基础提交 `4a3a4ab97d76f3317d68e64570a0c14318329a5b`；新增 S7 夹具当时尚未提交。输入源、PLAN 快照和源摘要在 `native-idAExSCX/source/`、`native-idAExSCX/logs/source-sha256.txt`，本轮不涉及密码算法输出或原始时间 CSV。

| 项 | 本机软件资格 | 原生动态定位 |
|---|---|---|
| 环境 | Darwin arm64 | Linux nss-m 6.17.0-35-generic x86_64 |
| 编译器 | AppleClang 21.0.0.21000334 | GCC 13.3.0 |
| CMake | 4.3.2 | 3.28.3 |
| 普通配置 | RelWithDebInfo，C11，严格警告 | RelWithDebInfo，C11，严格警告，Memcheck hook 开 |
| 动态工具 | ASan/UBSan；本机无 Valgrind | 系统 Valgrind 3.22.0 Memcheck |
| 自检 | 普通 2/2，ASan/UBSan 2/2 | 普通 2/2 |
| 采数/调频 | 未运行/无写入 | 未运行/无写入 |

本机普通编译选项和 ELF 外的 ARM 产物摘要见 `local/build-options.txt`、`local/binary-sha256.txt`；原生编译及链接选项见 `NATIVE_BUILD_OPTIONS.txt`。后者是从远端构建树只读取得的补充件，不在原归档内。Valgrind 头文件为 Ubuntu 系统安装版本，摘要也在该补充件。

原生唯一物理根为 `/home/nss-marker/yhr/Cry/platform-s7-20261016-idAExSCX`；上传包、源码、构建、日志、TMPDIR/TMP/TEMP 和缓存均在其内部，无源码符号链接。归档为同级 `platform-s7-20261016-idAExSCX.evidence.tar.gz`，SHA-256：

```text
093fd41b7bf544f6bf6f0d67f06c3e01d1e7d55a3f71b84c5f27221583be81fe
```

下载的完整归档位于本机 `build/platform-s7/native-idAExSCX.evidence.tar.gz`，摘要与远端一致；本目录的 `native-idAExSCX/` 为原样解包内容，包含上传时的 AppleDouble 元数据。完整源码与构建产物在远端保留。共享 SSH 由主控管理，本路未关闭。

原生普通二进制 SHA-256：

```text
on   41b6dedcd68baa34f102ec5f98010141c3de5c61805864ad3af86071f0194912
off  f2936f3cde4ec085ded5e13e7dc8faba93f0cf75e267bd41af36c533eea5d46e
```

本轮没有申请 CPU2/CPU6 采数独占、锁频或统计家族。不能把软件自检耗时当成性能数据，也不能把 ARM 产物当作 x86_64 实测。
