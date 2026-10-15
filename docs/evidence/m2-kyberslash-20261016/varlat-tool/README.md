# S3：Valgrind varlat 实际工具构建

状态：完成。2026-10-16 在真实 `nss-m`、Linux x86_64、GCC 13.3.0 上构建 Valgrind 3.25.1，并成功应用 KyberSlash 两份 `20250805` 原补丁。实际 `valgrind --tool=memcheck --help` 显示：

```text
--variable-latency-errors=no|yes check for variable latency errors [no]
```

这是工具构建与选项就绪证据；M2 未修/已修秘密标记探针由 S4 独立记录，不能用本页替代 M2 定位对照。本路没有时序采样、锁频、sudo 或密钥恢复。

## 固定输入

| 输入 | 固定身份 / SHA-256 |
|---|---|
| Valgrind 官方 tag | `VALGRIND_3_25_1`，tag 对象 `97a957e037fe3654655c9bfd2fdbd707572ca2a2`，解引用提交 `4441567fbec8c263e1624b49ba86572d4cccfccd` |
| 官方 `valgrind-3.25.1.tar.bz2` | `61deb8d0727b45c268efdc1b3b6c9e679cd97cbf5ee4b28d1dead7c8b7a271af` |
| `valgrind-try-patch-20250805.txt` | `6c0a69ef5372b335edc48430520352ec5844d2bafb16e7ef3688d2b3f8fe00ff` |
| `valgrind-varlat-patch-20250805.txt` | `7e6518012a3caee69c5665c3a4c7f6419e290d4f1c9ec5a92fac14996a7d7922` |
| 同提交补入 `.gitignore` 原件 | `047493446f5a902837c99dbc339bfc92a3efe69fce39733cf8d8fc6855667c45` |

发行包来自 [Sourceware 官方目录](https://sourceware.org/pub/valgrind/valgrind-3.25.1.tar.bz2)，两份补丁分别来自 [try 补丁](https://kyberslash.cr.yp.to/valgrind-try-patch-20250805.txt) 与 [varlat 补丁](https://kyberslash.cr.yp.to/valgrind-varlat-patch-20250805.txt)。补丁原件在本目录与 `third_party/valgrind-varlat/patches/` 逐字一致。上游许可证为 GPL v2，副本 `VALGRIND_COPYING` 保留。

官方发行包没有 `.gitignore`；第一次 varlat dry-run 因该文件缺失退出 1，日志 `varlat-patch-dry-run.txt` 原样保留。随后从 [Sourceware 同提交 blob](https://sourceware.org/git/?p=valgrind.git;a=blob_plain;f=.gitignore;hb=4441567fbec8c263e1624b49ba86572d4cccfccd) 恢复缺失原件，完整 dry-run 和应用均退出 0（`varlat-patch-dry-run-complete.txt`、`varlat-patch-apply.txt`）。没有编辑原补丁或修改密码实现。

发行包的分离签名已在本机独立 `build/platform-s3/gnupg/` keyring 验证：签名子钥指纹 `12768A96795990107A0D2FDFFC57E3CCACD99A78`，主钥指纹 `EC3CFE88F6CA0788774F5C1D1AA44BE649DE760A`。公钥从 Valgrind 下载页链接的 [Mark Wielaard 公钥页](https://www.klomp.org/mark/gnupg-pub.txt) 获取；GPG 报告 Good signature，同时明确密钥信任状态未认证，未把该检查写成额外身份担保。原 `.asc` 和 `release-signature.txt` 已保存。

## 真实构建与目录边界

远端唯一根为 `/home/nss-marker/yhr/Cry/platform-s3-20261016-cc79de28-2da`，`readlink -f` 已核对；输入在 `incoming/`，源码在 `valgrind-3.25.1/`，输出在 `build/` 和 `install/`，临时与缓存为 `tmp/`、`cache/`。没有改动 `HOME`。完整命令入口是本目录 `build_linux.sh` 的执行原件。

构建配置：`--enable-only64bit --disable-maintainer-mode --disable-dependency-tracking --with-tmpdir=<本根/tmp> --prefix=<本根/install>`，`make -j4` 和 `make install` 均退出 0。使用发行包预生成 Makefile；没有安装 autoreconf/automake，也没有运行上游测试套件。补丁加入的测试清单不通过本次构建宣称已经执行。

`TEMP_PATH_REVIEW.txt` 记录了显式路径审查。configure 中 `/usr/bin/mktemp -d` 遵循树内 `TMPDIR`；`--with-tmpdir` 同时把工具编译默认临时根钉在本树，覆盖源码 `/tmp` 默认分支。上游完整测试中可能有硬编码路径，本次未执行。全部工具树符号链接的解析目标均在本根，违规清单 `symlink-boundary-violations.txt` 为空；完整映射保存在日志归档。

实际工具身份见 `ENV.txt`、`binaries.sha256`：

- `install/bin/valgrind`：`8bfc2182af72f789be4752542a014da371ad93149c67c00720826734a895bf64`。
- `install/libexec/valgrind/memcheck-amd64-linux`：`c040a127b5c61fdc0c3b0b7fb94edd869fc8248416733cde84ad3b6b56dd48f6`。

`tool-logs.tar.gz` 保存完整 configure、make、install、补丁、环境、help 与路径映射日志，下载前后 SHA-256 相同：`815e96ef1b2d1d246db8f4d829c02ab19bfcebb9026e6870c57059a1dbcfde93`。远端原件和归档均保留；本机第三方源码、发行包与打补丁树保存在 `third_party/valgrind-varlat/`，该目录按仓库既有规则被忽略，不冒充已随 Git 保存源码。

## 使用方式

仅从每个模块自己的 Cry 根运行，导出该根内 `TMPDIR`、`TMP`、`TEMP`、`XDG_CACHE_HOME` 后使用：

```sh
<S3根>/install/bin/valgrind --command-line-only=yes --tool=memcheck \
    --variable-latency-errors=yes --track-origins=yes --vgdb=no \
    --vgdb-prefix=<模块根>/tmp/vgdb --log-file=<模块根>/varlat.log \
    --error-exitcode=99 <模块探针>
```

探针须通过 `<valgrind/memcheck.h>` 的 `VALGRIND_MAKE_MEM_UNDEFINED` 明确标记秘密，并在结果消费前适当地标记输出为已定义；错误栈必须指向被测路径，不能把普通未初始化输出误认作目标除法命中。`--try` 补丁只提供可选参数兼容，本次实际定位应显式要求 varlat 选项，避免工具缺功能时静默降级。

M1 vendor 和封存结论均保持只读；本路没有修改根 CMake、stage、commit 或 push。锁频与统计未执行，dudect 不进入 Holm 家族。
