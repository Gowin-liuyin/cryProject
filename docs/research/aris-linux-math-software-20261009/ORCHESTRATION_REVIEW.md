# Linux软件编排原始审查记录

2026-10-09。本页保存代理`/root/linux_math_qa/script_review`的三次最终回复原文。
审查范围是本模块的合同、两份shell、CMake及只读CTest脚本与本地stage；不是外部同行评议。
编写者和审查者没有远程操作、认证或新成本采集。下列通过结论不代表Linux矩阵已执行。

## 当前字节身份

下列SHA256于补存本页时重新读取实际文件；stage未因增加本页而重打包，本页不在上传件内。

| 文件或准备件 | SHA256 |
|---|---|
| `remote-run.sh` | `0a78212a08e5ef13c5cafaf2821ace5ef3cdb0358833927ae493575ef66a9c91` |
| `matrix-run.sh` | `16f0d5eba2ee01f9d42a7ef5c05dbceeccc1bb0556b34c44c106576115a82c78` |
| 本模块`CMakeLists.txt` | `affd7b295f4c2b32a7d4b4e7139c8cb999d0c779fde8dd4b73d88870af89ae99` |
| `readonly_check.cmake` | `f4236f7da88a831c163cedd5de2c7b335f970c0f37848102b23aa11ad9d9767c` |
| stage内原观察器`CMakeLists.txt` | `85fb303e9932a679e2a5471a92ce42acea1859f84cf667a60b8ad851173820ef` |
| stage内原审计`audit/CMakeLists.txt` | `f283c088e6730950e0ee5aa54e16440c62de3c5fc6bb5f5ab17df7916474e018` |
| stage内原汇总`CMakeLists.txt` | `70820a849c8ff5667105df4e61c6529044c6da8f7929ce91db5e9519528feb33` |
| `linux-math-software-stage.tar.gz` | `6b3ba2c6ed62d80ee4ec39824f18e1430185652e9a94c9b979c12703f234d0fc` |
| stage的`STAGE_SHA256SUMS` | `874cf30e3139bb3e9d2563f6c76c00db3a0b30d05325b8183cc6d1f03f8e4ca8` |
| stage的`STAGE_PATHS.txt` | `feb3e0c1dca6ffcb9f4fe5e684e1e7d1bfa53ce5c78f29febdc36cb5a250a7ee` |

上传件194086字节，264文件、263摘要项。原数学源码ZIP的56ad身份和汇总C的2e33身份见合同，保持原字节。

## 第一次最终回复：四项必须修正

以下行号指修正前的单文件编排，之后拆成无条件超时入口和矩阵正文；原文不重编号。

```text
What this change does: It runs four Linux software-check cells and compares four M02 JSON outputs byte for byte. The shell syntax check passed.

Must fix:

1. **CTest continues after the first failing test** — `remote-run.sh:69,78,89,98`. Each invocation lacks `--stop-on-failure`, so remaining tests run after failure, contrary to `CONTRACT.md:40`. Add that option to all four invocations.

2. **Outputs can enter the read-only stage** — `remote-run.sh:14-27,41,118`. An output path beneath `stage_root` is accepted. Both checksum checks can still pass because `sha256sum -c` ignores new files. Reject stage-descendant outputs and verify the complete stage inventory.

3. **Inherited environment can disable the deadline** — `remote-run.sh:8-12`. Starting with `A113_MATH_SOFTWARE_DEADLINE=active` bypasses the only timeout. Enforce the deadline through a launcher that inherited environment cannot disable.

4. **Failed binaries lose promised diagnostic records** — `remote-run.sh:69,100-108`. A collector CTest failure stops the cell before linked libraries and symbols are recorded. Capture those records immediately after each successful build, before its tests.

No direct formal timing or cryptographic launch appears in these four files; the original failure fixture is within the approved scope.

Verdict: fix 1–4 first. Not checked: fixed upstream CMake/C sources, stage contents, or remote execution.
```

## 修正后最终回复

```text
Scoped review passes. All four previous findings are fixed; no remaining blocking issue found in the five-file module.

Verified both shell scripts parse, all four CTest calls stop on failure, timeout is unconditional, outputs cannot enter stage, and binary metadata precedes tests. The local stage inventory matches 264 files; all 263 hashes and four verification copies match.

No remote or formal collector execution performed.
```

## 绝对路径和预检失败即停的最终复查

```text
Confirmed: the additions introduce no blocking issue. Both scripts still parse, relative paths are rejected before resolution, and all five provenance commands now fail closed.

The refreshed stage remains valid: 264 files match its inventory, all 263 hashes pass, and all four verification files match the reviewed module. No remote or collector execution performed.
```

## 本地执行、失败与表述更正

本地已有macOS/ARM C二进制只读执行4项新编排CTest，通过4/4；三个M02审计JSON及跨进程汇总
与封存参考逐字节相同。没有调用有效输入的正式观察器，也没有再次执行20对完整统计函数。
原缺输入失败夹具的调用属于下一阶段固定软件测试，不是本地新成本采集。

第一次stage装配把每个M02目录误计为32项，实际还有`input-records.tsv`，总数33。工具返回原片段为：

```text
Traceback (most recent call last):
  File "<stdin>", line 37, in <module>
AssertionError: 33
shasum: build/aris-linux-math-software-20261009/linux-math-software-stage.tar.gz: No such file or directory
```

部分stage保存为`build/aris-linux-math-software-20261009/stage-incomplete-file-count/`，未进入上传件。
修正集合后干净重装，三个目录各33项均保留原字节。已有输出的负向检查真实返回非0且四份JSON摘要不变：

```text
CMake Error at docs/research/aris-linux-math-software-20261009/readonly_check.cmake:15 (message):
  Read-only audit outputs must be new
```

补存时重新读取`local-path-rejection.log`发现该本地测试实际在GNU参数解析处退出，原日志为：

```text
realpath: illegal option -- e
usage: realpath [-q] [path ...]
```

因此，这一退出2仅证明macOS上该GNU依赖入口没有继续创建输出，**不能证明已运行到固定工作根拒绝分支**。
此前`LOCAL_PRECHECK.json`的`path_rejection_passed=true`和交接中“拒绝非约定根”的措辞需要主代理
在提交前更正；编写者已明确通知主代理。相对路径拒绝检查发生在`realpath`之前，确实执行并返回2；
固定根及stage子路径限制在本轮仅由静态编排审查核对，仍待真实Linux适用检查。

本地日志身份如下，主代理另将原日志复制到新准备证据目录，本页不替代日志：

| 日志 | SHA256 |
|---|---|
| `local-configure.log` | `12bf0cefd9a98e03f21255c16653421f8c77e7bb736ad51c03c64714f903d6dc` |
| `local-ctest.log` | `ee84b7a6bf3d6b9289ac0efcf2381eb9df6fe2c515b85f32139766a91070fa50` |
| `local-existing-output-rejection.log` | `8119f6dd1b4e74b9896afb2feb04eb0518e097b8a774f27e94c8e8a24d6d8e93` |
| `local-path-rejection.log` | `2fe58e19dec2bbd950993ee6506c206269ef6a03e4621a52d92cc00c58623bff` |

本页不签收Linux编译或动态检查、Linux计时、跨平台成本、R02/R04、独立性、真实总体FPR/TPR或恒时。
