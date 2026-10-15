# M5 完整解封装原生定位与资格结果（2026-10-16）

**定位**：固定mlkem-native portable reference完整解封装在真实Linux/x86_64、Clang18普通产物上，
对PKE秘密1152字节与拒绝z32字节明确标记，2公开seed×5类输入，在发行版Memcheck、
S3 patched varlat=no、patched varlat=yes三模式均退出0、0 errors/0 contexts。
公开key/hash/ciphertext不标秘密；没有意外命中，也没有为消除命中修改密码路径。

**统计**：本轮未执行measure计时或原生online dudect采集，没有M5 raw时间样本、CI/Holm/RTLF判决。
online dudect已构建并通过不读钟callback与合成raw写出自检，不能据此填“阴性统计通过”。

**边界**：这是固定源码/编译器/后端、两key与十有限公开输入的动态无命中观察，
不是任意输入、所有编译器/微架构的恒时证明或总体误报认证；无密钥恢复/exploit，旧M1结论保持。

## 实际核对

| 项 | v2结果 | 原件位置（资格归档内） |
|---|---|---|
| 普通C11资格 | 7/7 | logs-v2/ctest-ordinary.log、lasttest-ordinary.log |
| ASan/UBSan资格 | 7/7 | logs-v2/ctest-sanitize.log、lasttest-sanitize.log |
| 独立NIST功能 | 25keygen+25encap+10decap，10公钥/10私钥检查；5接受/5隐式拒绝 | 上述reference_kat原输出 |
| 公共参数与随机失败 | 错长/空指针/随机源失败等既有reference检查通过 | 上述日志 |
| system Memcheck | exit0，0 errors/0 contexts，10标记完整调用 | logs-v2/system.* |
| patched varlat=no | exit0，0/0，10标记完整调用 | logs-v2/varlat-no.* |
| patched varlat=yes | exit0，0/0，10标记完整调用 | logs-v2/varlat-yes.* |
| 实际标记 | stdout显式mode=valgrind_secret_marked；native --poison返回77 | 各stdout及CTest |
| 调用链 | harness→mlkem_decapsulate→baseline_native_dec→indcpa_dec+重加密+比较+拒绝KDF | poison.symbols/poison.disasm、源码 |
| online dudect | 同reference库，原上游header；无读钟自检/原始CSV合成自检通过 | dudect-link.txt、dudect.disasm、CTest |
| 时序采集/调频 | 未运行/未写入；restore_match不适用 | 本轮命令及工作范围 |

实际普通符号地址包括`mlkem_decapsulate=0x17e0`、`baseline_native_indcpa_dec=0x7850`、
`baseline_native_dec=0xa3e0`，只对本ELF有效，不把地址搬到新构建。
自有harness一致性比较是在调用完成、输出恢复defined后进行；它不替代独立KAT。
Memcheck使用客户端秘密标记方法，未把第三方ctgrind仓库“已clone”冒称其独立二进制已执行。

## 采集入口已准备，尚未执行

主控先提交[PLAN](PLAN.md)及固定执行清单，核对[ENV](ENV.md)的源码/ELF摘要，再由唯一锁频任务调用：

- `<根>/build-v2-ordinary/reference/measure RUN_ID SEED 10000 NEW_RAW.csv NEW_META.txt`
- `<根>/build-v2-ordinary/platform_m5_dudect --collect --seed SEED --raw NEW_DUDECT.csv`

这两行是**待执行合同**，不是本轮运行记录。online原始CSV保存begin/end tick与相邻周期差、类别、
阶段及uncropped成员；每批最后一次无下一tick，end/duration留空，不补造耗时。
每批完成flush，未完成批次若中断仍可能没有落盘，必须标不完整。

三次同机确认按PLAN预定seed/core，参数族仅3个Welch近似p，Holm α=.05；RTLF/dudect族外。
阴性一致性、任何阳性或工具异常均依真实后续数据填写，不以当前无命中代替统计。

源码、完整归档、工具身份、原始摘要与Cry边界详见[ENV](ENV.md)。
阻塞：无软件/动态定位阻塞；正式统计仍待主控提交PLAN与串行锁频运行。

---

## 本轮锁频端到端结果（2026-10-16，控制器 `a3c9ca1`）

采数条件：boost=0 / performance / min=max=4300000 kHz / taskset CPU2 或 CPU6；
三次运行 seed 31337-CPU2、424242-CPU2、31337-CPU6；每类 10000 次、预热 100 在窗口外。
6 次控制器运行全部 `restore_match=yes`（3 次 measure + 3 次 online dudect）。
原件见 [platform-collection-20261016](../platform-collection-20261016/README.md)。

**1. 定位**：`mlkem-native` 参考路径，本机调用链确认；Valgrind poison 与 varlat 均为 0 未解释命中，
ctgrind 秘密标记无命中。这一层是"未发现"，不是"已证明恒时"。

**2. 统计**：家族 `m5_reference_end_to_end_v1`，**m=3**（单一 reference 臂 × 3 次运行），α 全族 0.05。
三次的原始 p = 0.249、0.410、0.427，**Holm 拒绝数 0**；固定效应合并
Δ = −5.30 ns，95% CI [−11.77, +1.16]（含 0），I² = 0%。
族外：RTLF α=0.01 结果见 [platform-rtlf-20261016](../platform-rtlf-20261016/RTLF_RESULT.md)；
online dudect 三次 max|t| = 2.10、1.98、2.82，状态 `state=1`（预算内无证据），**不进 Holm**。
对照类对（`bit-flipped` vs `random`，族外）三次 p = 0.020、0.475、0.240，方向不一致，不作泄漏证据。

**3. 边界**：本结论只覆盖本机 x86_64、固定编译产物、message-zero vs message-ones 类对、
每类 10000 次、三次运行预算。"CI 含 0 且 Holm 不拒绝"是**未检出**，
不构成恒时证明，也不给出总体误报率为零的结论；dudect 的最大 t 未被转换成伪 p。
