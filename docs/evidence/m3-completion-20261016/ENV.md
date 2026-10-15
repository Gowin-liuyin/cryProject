# M3 完整解封装夹具环境

本轮日期为 2026-10-16（Asia/Shanghai）。开发在 macOS/ARM 的仓库 main；功能与定位另在真实
`nss-m` x86_64 Linux 执行。云端文件没有使用默认 `/tmp` 或 `/run` 项目工作路径。

| 项 | 本轮实际值 |
|---|---|
| 固定密码源 | `vendor/mlkem-native/PIN.md` 的 `b3ba7b32773e657dd37f6f87bce82528459ad8a4`；未改 vendor |
| 自有代码包装时 HEAD | `44c209af65546eb3df3bdf5b165f52a7ef76feab`，另含明确记录的未提交并行修改 |
| 源码上传载体 | `38098e0f31ec354c1b8e0205b2f65b8fd2ee2277ee9cbbb6a245a35741b9bb1a`（SHA-256），348 文件 |
| 原生唯一物理根 | `/home/nss-marker/yhr/Cry/platform-m3-20261016-8b6f2d91` |
| 临时/缓存 | 根下 `tmp/`、`cache/`、`cache/ccache/`；源码、测试转录、构建和日志也在根下 |
| OS/内核/ISA | Ubuntu 24.04.4，Linux 6.17.0-35-generic，真实 x86_64；硬件原始信息见 `native-hardware.txt` |
| 编译器与构建 | Clang 18.1.3、CMake 3.28.3、Unix Makefiles，最多 `--parallel 4` |
| 普通配置 | RelWithDebInfo、`-O2 -g -DNDEBUG`、C11、无 LTO、严格警告、`PLATFORM_M3_LUT_LEAK=1/0` |
| 动态配置 | 独立 `build-sanitize`，Debug、ASan/UBSan、`-O1 -g -fno-omit-frame-pointer` |
| 秘密地址工具 | 系统 Valgrind 3.22.0 / Memcheck 标准 client requests；不是 KyberSlash varlat |
| 时序/频率/隔离 | 没有执行 measure、调频、MSR、boost/隔离写入；restore_match 不适用 |

远端 source export 的 348 文件逐一核对通过；native build identity 中的 `source_commit` 字段是
export 清单摘要前缀，不是 Git 提交，不能把它误认为干净 commit。
载体还原的明确源文件摘要在 `source-SHA256SUMS`，上传时工作区状态在 `source-upload.json`；
独立运行 helper 的摘要在 `native-8b6f2d91/carrier-SHA256SUMS`。

普通和动态构建各运行六项 M3 CTest，均 6/6；本机 Apple Clang 21/macOS arm64
也在两套新构建中各 6/6。动态检查产物没有参与秘密地址工具或任何计时。

原生普通 measure 的摘要：

- on：`fe5435ba563cdd57df2f78ac6c53005685af377c31e9da2a5000eea426bb1929`
- off：`d62e39124660f758a6cc98b82b3bd9b8e41a45b0ccdc46a83bc6c6ddd73df4f0`

原生普通 probe 的摘要：

- on：`49dbba651d0103201946b0db90c1fecf7825dd16e0a23189867785bb9bcf3bfa`
- off：`58474265834d1e28514596d5ced82d42d8828b11e4106b18dcdf833887ee221f`

完整原生树与同级原归档保留，未覆盖复用：
`/home/nss-marker/yhr/Cry/platform-m3-20261016-8b6f2d91.tar.gz`，SHA-256
`4b9acf9647a8613b987f97862513d50fedaa3414733fa32677a45fbc17353e96`。
全包本机副本在 `build/platform-m3-s6/native-full-8b6f2d91.tar.gz`，独立核对摘要相同；
该 build 副本不是正式证据目录。本目录保存可审阅的原日志、反汇编、清单、身份和核对结果，
远端原树/归档是完整保留件。结束进程扫描空、树内符号链接清单空，调用者亲和性 0—31；
共享 SSH socket 按主控要求保持，不以 socket 存续误报实验仍在运行。
