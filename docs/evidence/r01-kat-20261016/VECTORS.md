# T05 向量来源总表（r01-kat-20261016）

本表逐行给出「模块 × 版本」实际跑过的公开向量例数、通过数、日志与来源标识。
所有数字都来自本目录 `logs/` 下的原始日志或 `logs/remote-manifest.sha256` 固定的产物摘要；
未跑过的例数一律显式写成"不适用"，不把文件里的例数当成通过数。

- 远端唯一可写根：`/home/nss-marker/yhr/Cry/r01-kat-20261016-2ff55778bc52/`
  （`drivers/` 驱动源码、`build/` 可执行文件、`logs/` 原始日志、`out/` 逐例摘要）。
- 运行机器：`nss-m`，x86_64，Linux 6.17.0-35-generic，AMD Ryzen 9 9950X（32 线程），
  `cc (Ubuntu 13.3.0-6ubuntu2~24.04.1)`；`logs/run_remote.out` 有环境与全部编译命令行。
- 全部只读引用已冻结的树与证据；没有修改任何 `tests/`、`src/`、`vendor/`、`sources/` 或已封存证据。
- 运行期间所有临时目录都指向新根 `tmp/`，没有在 `/tmp` 落任何文件。

## 总表

| 模块 | 版本 | 向量来源 + commit / SHA-256 | 例数 | 通过数 | 日志路径 | 备注 |
| --- | --- | --- | ---: | ---: | --- | --- |
| M1 liboqs 0.10.0（未修，clangover） | `build/historical-clangover`（Clang / `-Os -fno-vectorize`） | `liboqs010-historical-20261015-86131c2/tests/vectors/mlkem768.txt`，SHA-256 `c94dda2717eb370dddfe5b7ca7a7f58d789e0f63238a486e464ce40c673817f4`（由 ACVP 转换件固定，见下） | 80 | 35 | `logs/t05_m1_clangover_kat.log` | 已执行 60 例中通过 35 例：keygen **0/25**、encap 25/25、decap 10/10（含 5 例隐式拒绝）；`ekcheck/dkcheck` 各 10 例记为不适用（历史 liboqs 封装层无输入校验入口）。退出码 1，原因见「M1 keygen 0/25 的来源核对」 |
| M1 liboqs 0.10.0（已修 `982c762`） | `build/historical-fixed-982c762`（`LIBOQS010_SOURCE_DIR=liboqs-0.10.0-982c762`） | 同上向量文件与 SHA-256；上游修复提交 `982c762c242ef549c914891b47bf6e0ed6321f91` | 80 | 35 | `logs/t05_m1_fixed982c762_kat.log` | 与未修行逐项相同：已执行 60 例中通过 35 例（keygen 0/25、encap 25/25、decap 10/10），keycheck 20 例不适用 |
| M1（树内自带目标） | 两版 `historical/test_selftest` | 树内 `tests/test_historical_selftest.c`（系统随机往返，不含向量期望值） | 1 | 1 | `logs/t05_m1_clangover_selftest.log`、`logs/t05_m1_fixed982c762_selftest.log` | 这是该树为 historical 变体提供的唯一自带目标，只做 keygen/encap/decap 往返，不计入上表 80 例 |
| M2 pq-crystals kyber768（未修） | `a621b8dde405cc507cbcfc5f794570a4f98d69cc`（2023-05-09，vendor 归档 SHA-256 `509548a1741473cab69fe403eb685282419bc2a42554d358f16b9e991c88ac08`） | `tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp`，SHA-256 `a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2`（官方第 3 轮提交包成员原字节） | 100 | 100 | `logs/t05_m2_unfixed_kat.log` | `m2_platform_kat` 逐例 keygen+encap+decap；日志原文 `m2-kyber768-round3-unfixed: 100 independent official round3 KAT keygen/encap/decap cases passed` |
| M2 pq-crystals kyber768（已修） | `272125f6acc8e8b6850fd68ceb901a660ff48196`（2023-12-29，vendor 归档 SHA-256 `e3d020a78c59fc7248f64a4ca774db5ca8c6bc537e8c682a9fd0049a09180803`） | 同上 `.rsp`（同一 SHA-256） | 100 | 100 | `logs/t05_m2_fixed_kat.log` | 日志原文 `m2-kyber768-round3-fixed: 100 independent official round3 KAT keygen/encap/decap cases passed` |
| M3 LUT-on（人工构造校准） | `platform-m3-lut-on`，源快照 `SOURCE_EXPORT.sha256` = `6eb6a54fafc43f7ae81599fd385cb66006d14811ec2f6e93faeff917d24059e9`；库 SHA-256 `744e82cd6e9426270cf47b54bd16812bd8bd77669d0e38f998c1638de10820f3` | `platform-m3-locate-20261016-4b102a339cc8/source/tests/vectors/mlkem768.txt`，SHA-256 `c94dda27…817f4`（同一 ACVP 转换件） | 80 | 80 | `logs/t05_m3_on_kat.log` | 25 keygen + 25 encap + 10 decap + 10 ekcheck + 10 dkcheck 全通过；日志含 `5 implicit rejections, 5 accepted ciphertexts` |
| M3 LUT-off（人工构造校准） | `platform-m3-lut-off`，库 SHA-256 `8345b0409e9885c0a211d5cb8378a4147293b64a9c7e7573630e0fc6a99239b2` | 同上 | 80 | 80 | `logs/t05_m3_off_kat.log` | 与 on 版逐项相同 |
| M4 人工比较夹具-vulnerable（人工构造校准） | `build-software-v3/test_platform_m4_vulnerable`，SHA-256 `97f30fc57107503e90828d336096d5a38b3a0a6bf93c5ed258d6714614488b57` | 无公开密码向量；人工夹具自检输入（`mismatch-first` / `mismatch-last` 两类各 1 例） | 2 | 2 | `logs/t05_m4_vulnerable_inputs.log`、`logs/t05_m4_vulnerable_describe.log` | 输出 `m4_inputs=pass timing_collection=not_run`；接口描述见 describe 日志。**人工构造校准，不对应真实密码算法** |
| M4 人工比较夹具-ct（人工构造校准） | `build-software-v3/test_platform_m4_ct`，SHA-256 `6e619f877e6bdac0084ba3fe68e8c398528c0cb8e7e76ae871fd9815f6ea8599` | 同上 | 2 | 2 | `logs/t05_m4_ct_inputs.log`、`logs/t05_m4_ct_describe.log` | 同上；两版 describe 文本逐字节相同（见 `logs/t06_m4_interface_cmp.log`）。**人工构造校准** |
| M5 参考路径 | `build-v2-ordinary/reference/test_mlkem`，SHA-256 `dc149211d152c6c1fa71d1ae6d81baa5fdde815a9ea75f2af92540a556149152`；源快照 `SOURCE_EXPORT.sha256` = `e17698d33ff07fddf385bae8118b0ff8b77ae711f147e3ad41f60c1a6edd618d`，上传包 SHA-256 `6c598f7ecfffac2d6737561af343dce9805da68b320fb8c595825d8a30bdc52d` | `platform-m5-20261016-30efdf66eb26/source-v2/tests/vectors/mlkem768.txt`，SHA-256 `c94dda27…817f4` | 80 | 80 | `logs/t05_m5_reference_kat.log` | 25+25+10 密码例与 20 例密钥校验全通过；`5 implicit rejections, 5 accepted ciphertexts` |

机器可读版本：`logs/T05_T06_summary.tsv`（同一批数字，制表符分隔）。

## 向量来源链

- `mlkem768.txt` 由本仓库 `tests/convert_vectors.sh` 从 NIST ACVP-Server
  `975de31eb83d87039ec88934fdc47d8c312b892d` 的 `gen-val/json-files` 原件按 `tcId` 关联生成，
  只提取 ML-KEM-768 的 25 keygen / 25 encaps / 10 decaps，不改预期字节（`docs/validation.md` 第 6–8 行）。
  上游 JSON 摘要：`keygen-prompt.json` `3f9ce34f…9523`、`keygen-expected.json` `a253d0ad…73a4`、
  `encdec-prompt.json` `998e22df…db91`、`encdec-expected.json` `9089ec6f…c1df`（`tests/vectors/SHA256SUMS`）。
  三个远端树里的 `mlkem768.txt` 与仓库本机副本 SHA-256 完全相同（`logs/run_remote.out` 的 provenance 段）。
- `PQCkemKAT_2400.rsp` 是 pq-crystals 第 3 轮提交包 `KAT/kyber768/PQCkemKAT_2400.rsp` 的原字节，
  获取与静态核对见 `tests/vectors/kyber768_round3/SOURCE.md`；远端 M2 树内副本 SHA-256 与本仓库一致。
- M1 的两版实现同属 liboqs 0.10.0 `ML-KEM-768-ipd`（`OQS_MINIMAL_BUILD=KEM_ml_kem_768_ipd`、
  `OQS_DIST_BUILD=OFF`、强制关闭 AVX2，只编 portable C `*_ref`）；未修版用 liboqs 0.10.0 原始树，
  已修版用同版本补丁副本 `liboqs-0.10.0-982c762`（上游修复提交 `982c762c242ef549c914891b47bf6e0ed6321f91`）。
  两版都未改动已冻结树，只在只读路径外编译了本目录 `drivers/m1_kat.c` 作为最小驱动。
  `-Os -fno-vectorize` 是复现 clangover 公告条件所需的选项（`logs/run_remote.out` 中 `LIBOQS010_C_FLAGS`）。
  任务指名的 `historical/measure`、`historical/baseline`、`historical/test_selftest` 两版摘要记录在
  `logs/t05_m1_binaries.log`（本轮只运行了 `test_selftest`，没有运行计时入口 `measure`）。
  "未修 / 已修"的身份由只读 diff 核实：`logs/t05_m1_fix_identity.log` 显示 `982c762` 把 `poly_frommsg` 的
  `mask = -(int16_t)((msg[i] >> j)&1); … mask & ((KYBER_Q+1)/2)` 换成 `cmov_int16(...)`，
  并在 `verify.c` 新增 `cmov_int16`；两棵树对应文件的 SHA-256 一并记录在该日志里。

## M1 keygen 0/25 的来源核对

不是本驱动或远端环境的问题，也不是"向量装错"：liboqs 0.10.0 里被接入的是 FIPS 203 **初始公开草案（ipd）**实现，
其 K-PKE.KeyGen 与该树内最终稿参考不同。`logs/t05_m1_ipd_keygen_note.log` 记录了只读源码摘录：

- `liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/indcpa.c:217`
  → `hash_g(buf, coins, KYBER_SYMBYTES);`（无参数集域分隔字节）；
- 同仓库同步的最终稿参考 `vendor/mlkem-native/mlkem/src/indcpa.c:464`
  → `coins_with_domain_separator[MLKEM_SYMBYTES] = MLKEM_K;`（`MLKEM_SYMBYTES + 1` 字节输入）。

因此 keygen 的期望值必然不同，而 encap（用向量给定的 ek 与 m）与 decap（用向量给定的 dk 与 ct）
与最终稿一致，这也正是 25/25 与 10/10 通过的原因。该树的
`docs/historical-liboqs-0.10.0.md:18` 本身就写明：这个历史变体**不做**与 `tests/vectors/mlkem768.txt`
的 KAT 绑定，只提供系统随机往返 selftest。所以此处如实记录 0/25，不把 IPD 冒充最终 FIPS 203，
也不用它给 M1 的时序结论加分。

## 边界与不声称的内容

- 这些数字只说明各版本在各自公开向量上的功能一致性，不构成常数时间、频率锁定或统计显著性的结论。
- M3、M4 两行是**人工构造校准**夹具，不对应真实第三方算法或真实漏洞；M4 更是纯软件接口夹具，
  没有密码语义与共享密钥。
- M1 的 clangover 时序阳性条件（x86_64 + Clang 15–18 + 指定优化选项）与本表的 KAT 例数无关；
  本轮没有做任何计时采集，也不声称打穿哪一个变体。
- `ekcheck/dkcheck` 例数记为不适用是接口事实（历史封装层没有公开校验入口），不是为了凑通过数。
