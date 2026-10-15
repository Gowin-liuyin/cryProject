# M2 KyberSlash 本轮结果

状态：**定位完成；时序统计未运行。** 采用工程计划允许的 pq-crystals 历史 Kyber 路线。
PLAN 已先提交为 `4a44d7902a26e0482cae54820f9f2699ad99beb0`。

1. **定位**：在 nss-m x86_64 Linux、Clang 18.1.3、`-Oz` 产物中，未修
   `poly_tomsg`、`poly_compress`、`polyvec_compress` 各有一个目标 `div`，
   已修各为零。20250805 Valgrind-varlat 在同一对秘密标记探针上报告
   未修 1280 errors / 3 contexts、exit 99，已修 0 / 0、exit 0。
   同两 ELF 禁用 varlat 后均为普通 Memcheck 0 / 0、exit 0。
2. **统计**：没有端到端或微基准时间 CSV；CI/Welch、Holm、RTLF、dudect 均未对
   M2 时间数据运行。工具合成 CSV 资格不能填充本行，也不能把未运行写成未检出。
3. **边界**：无密钥恢复。目标函数来自未修改的真实历史实现，探针输入是公开人工定位
   夹具；本轮没有完整 KEM 调用、独立 KAT 或物理时延证明。无报警不等于恒时证明。

| 项 | 未修 | 已修 |
|---|---|---|
| 上游完整 commit | `a621b8dde405cc507cbcfc5f794570a4f98d69cc` | `272125f6acc8e8b6850fd68ceb901a660ff48196` |
| exact tag | 无，以完整 commit 钉版 | 无，以完整 commit 钉版 |
| 快照 | `vendor/kyber-kyberslash-unfixed/` | `vendor/kyber-kyberslash-fixed/` |
| 动态探针 ELF SHA-256 | `c29fc3e9b44d010ae7145eecc3dec61d7fbe66cd761f0852703df5206bb2f125` | `f5c062d61a5108d3bc5d0643d661a28dfef2483a661c06270e1815a4db86e730` |
| 可运行资格 | 普通/秘密标记构建各 CTest 2/2（两变体合计） | 同左 |
| varlat=yes | 三个真实热点命中 | 对应命中消失 |
| varlat=no | 0 errors | 0 errors |

`dda29cc63af721981ee2c831cf00822e69be3220` 仅修 KyberSlash1；本轮已修对照使用
同时包含 Slash1/2 修复的后续提交，未把中间点当作完整已修。
对象是历史 Kyber768，不能冒称 FIPS 203 ML-KEM-768。

完整版本、秘密来源、反汇编、原日志、原件归档、复现与来源清单见
[VERSION_AUDIT.md](VERSION_AUDIT.md)；工具来源与启用见
[varlat-tool/README.md](varlat-tool/README.md)，实际环境见 [ENV.md](ENV.md)。
varlat 默认上下文 PC 落在系数载入处，不能把它直接当成静态 `div` 地址；
本轮以同 ELF 的数据流、源码、反汇编与 varlat 开关对照共同定位三个热点。
M1 vendor 和已有证据结论保持原件，本轮不重新签收 M1。

下一轮先冻结端到端/微基准采集合同与假设族，取得适用功能资格，核对频率管理和恢复路径，
再安排唯一的 CPU2/CPU6 锁频采数任务。当前不生成空的 `holm.csv` 冒充统计完成。
