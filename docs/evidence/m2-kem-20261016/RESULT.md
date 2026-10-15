# M2 完整历史 KEM 功能资格

2026-10-16。已接通未修/已修两份历史 Kyber768 的完整 keygen、encap、decap 与共享 CLI。
本轮完成软件资格和生产产物核对，**未运行 measure 采数、未执行本目录统计计划**。

| 检查 | macOS/ARM | nss-m x86_64 Linux |
|---|---|---|
| 普通 CTest | 7/7 | 7/7 |
| ASan/UBSan CTest | 7/7 | 7/7 |
| 官方round3公开KAT | 两版各100例 | 两版各100例 |
| 真实解密消息0/FF、64例隐式拒绝、跨版160类例等价 | 通过 | 通过 |
| 空指针、0/短/长/SIZE_MAX长度、随机源失败清零 | 通过 | 通过 |
| 两版baseline/measure生产构建 | 通过 | 普通和动态均通过 |

公开已有 expected 来自 CRYSTALS 官方2020-10-01第3轮提交包，完整100例 `.rsp` 原字节
保存在 `tests/vectors/kyber768_round3/`，SHA-256
`a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2`。
每例检查全部公钥、私钥、密文、共享秘密和解封装；不是自产答案。
NIST AES-CTR DRBG 是测试依赖，每例按32+32+32三次请求展开；普通生产API使用系统安全随机源。

原 `kem.c`、`indcpa.c`、验证与隐式拒绝均未改。系统随机失败在进入上游前返回，
内部回调只从已取得的线程局部随机量消费。封装层先验拒绝错误长度与空指针，
正确长度的无效密文继续返回0并生成原版 `SHAKE256(z || H(ct))` 拒绝秘密。
原始上游快照与上一轮已钉清单123×2逐项一致。

根入口由主控接入 `PlatformM2.cmake`，`src/main.c` 与 `src/measure.c` 加M2宏分支，
保留共享计时窗口及CSV协议；两版 `version` 均写明 historical/non-FIPS203。
新库/目标分别为 `platform_m2_{unfixed,fixed}`、`platform_m2_{unfixed,fixed}_{baseline,measure}`；
`platform_m2_check` 运行7条资格。生产measure实际仅依赖系统libc/loader，无OpenSSL、NIST DRBG或mock随机源。

最终原生普通measure摘要：

| 变体 | SHA-256 |
|---|---|
| 未修 | `dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7` |
| 已修 | `c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7` |

`native-qualification/*-mlkem_decapsulate.asm` 证实长度/空指针检查后进入各自原
`pqcrystals_kyber768_ref_dec`，完整重加密/验证/拒绝路径保留。
实际普通measure的三个热点 `poly_tomsg/poly_compress/polyvec_compress`，未修各1个div，
已修各0；本次没有重跑上一轮varlat动态探针，旧结果只按旧ELF身份引用。

原生源是未提交工作区导出，完整清单575条，manifest SHA-256
`7f721febeaaac826bc38de05b3470439d656792ac379a083baead82bc0b92146`。
不能将后续Git提交倒写成执行时已存在的源码提交。20个普通/动态ELF与11个原件摘要全部通过下载核对。
完整原包 `native-linux-original.tar.gz`（约18MiB），SHA-256
`79b6a153205cf93aa7e4f72571c8aa0bec887344e1c1738b145d83bbffe0bad3`，
原远端为 `Cry/platform-m2kem-20261016-d75a4019/` 和同级同名tar.gz，均保留。
45个符号链接无越Cry，结束检查无本树程序在运行；本路未调频或修改亲和性，共享SSH由主控持有。

本机早期资格通过构建目录中的延后include挂接同一模块，未抢改根入口；
最终Linux源导出和本机生产构建已经采用主控接入的根CMake/CLI宏分支。
格式检查、独立CMake格式检查及只读核心接口复核通过。

定位：完整生产ELF保留已知历史除法差异，实际调用路径和两版本均已核对。

统计：本轮未采数；`STATISTICAL_PLAN.md` 预留三run、两变体、每类10000，端到端族m=6，待主控先提交冻结。

边界：历史Kyber768非FIPS203；公开KAT与功能通过不构成恒时证明、真实总体检出率或计时精度认证。
已选消息0/FF是显式公开测试夹具，固定key下每类只有一份密文；没有密钥恢复或exploit演示。
