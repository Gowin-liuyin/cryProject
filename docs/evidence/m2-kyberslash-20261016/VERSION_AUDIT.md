# M2 KyberSlash 版本与指令审计

2026-10-16，S4。本轮完成历史 Kyber768 的源码钉版、真实 x86_64 Linux 反汇编及
秘密操作数动态定位。未运行端到端计时或微基准采样，未做密钥恢复。
采集前平台 PLAN 已提交为 `4a44d7902a26e0482cae54820f9f2699ad99beb0`。

## 钉版与来源

选用工程计划允许的 `pq-crystals/kyber/ref` 降级路线。本轮没有构建 liboqs 多个 tag，
也没有接触 M1 的 `vendor/liboqs-0.10.0` 或既有证据。两份都是原始上游快照，未植入除法。
对象为历史 **Kyber768，非 FIPS 203 ML-KEM-768**。

| 角色 | 完整 commit | exact tag | Git tree |
|---|---|---|---|
| 未修 | `a621b8dde405cc507cbcfc5f794570a4f98d69cc` | 无 | `56e43b8bc31ed092f925a6e75fb155a9c3174d38` |
| 仅 KyberSlash1 修复，中间点 | `dda29cc63af721981ee2c831cf00822e69be3220` | 无 | `2cbcdb0c58cfbf78fdd628d29e44cebabb8c1b1e` |
| KyberSlash1/2 已修对照 | `272125f6acc8e8b6850fd68ceb901a660ff48196` | 无 | `296de200e4af8c24fe72e6cb73ad1140f7fa536d` |

Git 记录确认是连续父链 `a621b8d → dda29cc → 272125f`。dda29cc 只替换
`poly_tomsg` 的除法，不能当作 KyberSlash2 同时修复；272125f 接着替换
`poly_compress`、`polyvec_compress` 的除法。已修提交日期为 2023-12-29，
官方库状态页列补丁日为 2023-12-30，两种日期保留原口径。

来源为 [官方库状态页](https://kyberslash.cr.yp.to/libraries.html)、
[KyberSlash1 修复](https://github.com/pq-crystals/kyber/commit/dda29cc63af721981ee2c831cf00822e69be3220)、
[KyberSlash2 修复](https://github.com/pq-crystals/kyber/commit/272125f6acc8e8b6850fd68ceb901a660ff48196)及
[论文 2024/1049](https://eprint.iacr.org/2024/1049)。库状态页原 HTML 保存在
`version-audit/libraries.html`；其 SHA-256 为
`7842ee3277f7914dc9c9e09d4e86d6188cd188c10a15d9cefbd554efbdc9b793`。
上游提交元数据及两源文件修复差异分别为 `version-audit/upstream-commits.txt` 和
`version-audit/upstream-remediation.diff`。

两个 `git archive --format=tar <commit>` 的 SHA-256：

| 快照 | SHA-256 |
|---|---|
| 未修 | `509548a1741473cab69fe403eb685282419bc2a42554d358f16b9e991c88ac08` |
| 已修 | `e3d020a78c59fc7248f64a4ca774db5ca8c6bc537e8c682a9fd0049a09180803` |

完整归档每份 123 个 Git 条目；上游、独立重取自检与远端上传的所有文件字节和符号链接目标
逐项一致。清单见 `version-audit/upstream-{unfixed,fixed}-manifest.tsv`，符号链接摘要针对
链接目标字符串，而非解引用后的文件。原 `LICENSE` 的 CC0/Public Domain 或 Apache-2.0
选项和 Keccak/AES 来源说明保留；另存 `version-audit/LICENSE.upstream.txt`。
目录外 PIN 和 `version-audit/fetch_vendor.sh` 支持干净重取，拒绝覆盖已有目录。

## 秘密来源与测到的范围

未修 `ref/kem.c:106` 的解封装先调用 `indcpa_dec`，后者在 `ref/indcpa.c:328`
将依赖解封装秘密的多项式传给 `poly_tomsg`。同一解封装在 `ref/kem.c:114`
重加密，序列化经 `ref/indcpa.c:91–92` 进入 `polyvec_compress` 和 `poly_compress`。
这说明三个热点在真实算法中的秘密数据来源，但本轮动态探针只直接调用三个热点，
没有执行完整 KEM 路径或证明其端到端可利用性。

探针 `version-audit/poly_probe.c` 生成固定、公开、规范范围 `[0,3328]` 的多项式，
在调用前以 `VALGRIND_MAKE_MEM_UNDEFINED` 标记整个多项式及向量为秘密；三个函数返回后
才解除标记并消费输出。没有真实密钥、秘密值输出、主动延迟或密码语义修改。
该固定输入是人工定位夹具，目标函数是未修改的历史真实实现。

## 原生 Linux 产物与反汇编

主机 `nss-m`，AMD Ryzen 9 9950X，x86_64 Linux 6.17.0-35-generic；
Ubuntu Clang 18.1.3，CMake 3.28.3。完整快照见 `version-audit/environment.txt`。
唯一构建配置为本目录 `version-audit/CMakeLists.txt`；两变体分开静态库与 ELF，
`KYBER_K=3`、`-Oz -g -fno-vectorize -fno-slp-vectorize`、无 LTO。
构建并发最多 4。普通和带污点请求的构建各通过 CTest 2/2，这只表示热点调用可运行，
不是独立 KAT、完整 KEM 功能正确或两版本密码语义等价认证。
执行时本轮新增 CMake/探针尚未提交；原包记录其完整文件字节，`SHA256SUMS` 同时固定两源文件、
两个独立内核库和两个 ELF；本轮交接提交不能倒写成执行前已有的源码提交。

| 目标函数 | 未修 ELF 内 `div` | 已修 ELF 内 `div` | 片段 |
|---|---:|---:|---|
| `poly_tomsg` | 1 | 0 | `disasm/linux-clang18-oz-*-poly_tomsg.asm` |
| `poly_compress` | 1 | 0 | `disasm/linux-clang18-oz-*-poly_compress.asm` |
| `polyvec_compress` | 1 | 0 | `disasm/linux-clang18-oz-*-polyvec_compress.asm` |

未修 `poly_tomsg` 中，从 `(%rsi,%rcx,2)` 读取系数，构成 `%edx:%eax` 分子，
在地址 `0x1877` 执行 `div %r9d`，公开分母 `%r9d=0x0d01=3329`。
两个压缩函数有相同的秘密分子/公开分母机制。对应已修函数使用乘法和移位。
整份 ELF 仍有公开索引、长度运算产生的除法，因此不能用全 ELF 的 `div` 总数替代路径审计。

最初在 macOS/ARM 主机做的 Apple Clang21 x86_64 交叉检查中，`-Os` 将未修常数除法
约减，`-Oz` 才保留 `divl`；该探索不作为 Linux 执行证据。最终以上表的真实 Linux
Clang18 `-Oz` 产物为准。源码有 `/3329` 并不保证每组编译选项都产生除法指令。

最终带污点请求 ELF 的 SHA-256：

- 未修：`c29fc3e9b44d010ae7145eecc3dec61d7fbe66cd761f0852703df5206bb2f125`。
- 已修：`f5c062d61a5108d3bc5d0643d661a28dfef2483a661c06270e1815a4db86e730`。

## Valgrind-varlat 对照

使用 S3 的 Valgrind 3.25.1 和两份原始 20250805 补丁。共同参数为
`--command-line-only=yes --tool=memcheck --track-origins=yes --vgdb=no --error-exitcode=99`，
另将日志、`--vgdb-prefix` 和所有临时/缓存目录置于本路 Cry 子树。

| 同一组带污点 ELF | `--variable-latency-errors=yes` | 退出码 | `--variable-latency-errors=no` | 退出码 |
|---|---|---:|---|---:|
| 未修 | 1280 errors，3 contexts | 99 | 0 errors，0 contexts | 0 |
| 已修 | 0 errors，0 contexts | 0 | 0 errors，0 contexts | 0 |

未修三条上下文分别命中 `poly_tomsg`（`ref/poly.c:188`）、`poly_compress`
（`ref/poly.c:28`）、`polyvec_compress`（`ref/polyvec.c:48`），每条均追溯到
client request。总次数与本夹具的 256+256+768 个系数运算吻合。
日志 `poly_tomsg` 上下文 PC 为 `0x400185d`，去除加载基址后对应同一 ELF 中的系数 load
`0x185d`，不是实际 `div` 地址 `0x1877`；本报告不将默认上下文 PC 等同于具体除法地址。
六份反汇编片段全部提取自最终 `build-poison` 的两份 ELF，原包也保留完整反汇编，
并非把普通构建的地址直接套到污点构建日志。
关闭补丁选项后两 ELF 均无普通 Memcheck 报警，支持这些报警来自目标可变延迟机制。
原日志、退出状态和源/ELF/日志摘要保存在 `version-audit/`，不以删除报警或抑制项取得阴性。

该工具报告秘密操作数落入可变延迟指令，不测量当前 Ryzen 上某次 `div` 的物理延迟，
也不表示已检测出本机端到端时间差。已修的本夹具阴性不是绝对恒时证明。

## 原件边界与复现

远端原件根为 `/home/nss-marker/yhr/Cry/platform-s4-20261016-7824/`，
同级 `platform-s4-20261016-7824.tar.gz` 完整保存原源码、普通/污点构建、日志、反汇编和缓存/临时目录。
没有在 Cry 外新建项目工作文件。原件未覆盖；主控共享 SSH 保持给其他路使用。
这轮没有修改 governor、boost、频率、亲和性或隔离配置，没有计时任务。

拉回完整原包为 `version-audit/linux-original.tar.gz`，SHA-256
`eb22ca36be7756ae269fcb747bbe5783a14651f15dd33685c86d1ad78b3f09c5`，
与远端摘要一致。早期上传包保留 macOS provenance 扩展头，GNU tar 给出忽略扩展头提示；
最终污点源上传关闭 xattr 打包，并逐项核对全部 246 个上游条目，源码字节一致。
两轮源码分别保留在原包 `source/`、`source-poison/`，未以新文件覆盖旧原件。

干净重取并构建：

```sh
sh docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh
cmake -S docs/evidence/m2-kyberslash-20261016/version-audit -B build/m2-probe -DCMAKE_C_COMPILER=clang-18 -DM2_VALGRIND_INCLUDE_DIR=/path/to/patched-valgrind/include
cmake --build build/m2-probe -j4
ctest --test-dir build/m2-probe --output-on-failure
```

脚本成功重取后必须保留上游许可证；若已有 vendor 目录，脚本退出 1，不删除、不覆盖。
重取成功自检与已有目录拒绝路径均已检查。Valgrind 执行须使用 S3 补丁工具并显式开启上述选项，
不能拿无头文件构建的 smoke-only 探针充当秘密污点定位。

定位：已在三个官方历史热点得到未修阳性/已修消失，并以同 ELF 关闭补丁选项得到阴性对照。

统计：本轮未采端到端或微基准时间列；CI/Welch、Holm、RTLF、dudect 均未运行。

边界：无密钥恢复；结论限于固定提交、Clang18、x86_64 Linux、`-Oz` 和上述热点；
不升级为当前处理器物理变时、端到端可区分或恒时证明。
