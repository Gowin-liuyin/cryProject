# 固定版本防护适用性审查

本轮查阅日期采用客户端日历：2026-10-07。固定库为
`b3ba7b32773e657dd37f6f87bce82528459ad8a4`；项目开工基线为
`6de20c492521760e984b708c24e41692bf311745`，之后的项目修改不改变该库快照。
具体本地检查时的源码身份、工作区状态及配置以
[原始构建身份](evidence/defense-review-20261007/build_identity.h.txt)为准，不能把开工基线
当作所有后来产物的身份。

本记录覆盖自有密码封装、随机源、核心编译单元、普通 CLI、audit 调度入口及其构建选择。
这是防御审查与配置核验，没有执行新的时序漏洞触发、利用、密钥恢复或自动漏洞复现实验。
未发现需要为固定库新增密码运算修复的依据；确认并修正了一处自有构建身份记录错误。
未查到公告、功能测试通过或源码看似无分支，均不足以推出实现绝对安全。

## 当前检查对象与来源

| 对象 | 实际配置或调用关系 | 可核查材料 |
|---|---|---|
| 算法与接口 | C11、ML-KEM-768；封装先检查空指针与精确字节数，再进入固定长度内核 | [mlkem.h](../include/mlkem.h)、[mlkem.c](../src/mlkem.c) |
| 核心编译单元 | `kernel.c`直接包含`mlkem_native.c`；`common.h`先读取自有配置；公共 API 头在另一个编译单元使用 | [kernel.c](../src/kernel.c)、[SCU 原件](../vendor/mlkem-native/mlkem/mlkem_native.c)、[配置原件](../include/baseline_config.h) |
| 后端 | 自有配置不启用原生算术或原生 FIPS202 后端，不替换 FIPS202；本轮有效宏为便携 C 与内联汇编值屏障 | [有效宏](evidence/defense-review-20261007/effective-macros.txt)、[实际编译命令](evidence/defense-review-20261007/kernel-compile-commands.json) |
| 随机源 | 上游 randomized API 禁用；普通封装调用系统`/dev/urandom`并传播错误；确定性入口仅用于公开测试夹具 | [random.c](../src/random.c)、[inputs.h](../include/inputs.h)、[main.c](../src/main.c) |
| 比较与隐式拒绝 | 重新加密、全长比较、`J(z∥c)`和条件选择均由固定上游实现完成；CLI 不报告比较标志或共享秘密 | [kem.c](../vendor/mlkem-native/mlkem/src/kem.c)、[verify.h](../vendor/mlkem-native/mlkem/src/verify.h)、[main.c](../src/main.c) |
| 分配与清理 | 默认栈分配；上游`MLK_FREE`零化中间缓冲区；封装清理随机种子和普通自测的解封装密钥、共享秘密 | [common.h](../vendor/mlkem-native/mlkem/src/common.h)、[mlkem.c](../src/mlkem.c)、[random.c](../src/random.c) |
| 构建隔离 | reference使用原件；三个历史变体各用独立构建副本及已有补丁；目标 IPO 关闭，仍需核实际外加 flags | [CMakeLists.txt](../CMakeLists.txt)、[配置记录](evidence/defense-review-20261007/configuration.txt)、[编译命令](evidence/defense-review-20261007/kernel-compile-commands.json) |
| 外部依赖 | 密码内核不链接 liboqs、AWS-LC 或 OpenSSL；`libm`服务统计；OpenSSL命令只在摘要交叉校验测试中作独立参照 | [CMakeLists.txt](../CMakeLists.txt)、[摘要测试](../tests/test_native_digest.c) |

本地检查环境为 Darwin/arm64、Apple Clang 21；有效宏记录`__CHAR_BIT__=8`、
`__INT_WIDTH__=32`。它确认配置记录与实际编译输入一致，不代替本轮真实 x86_64 Linux
功能、链接、产物和动态检查。真实服务器记录应绑定其自己的源码清单、编译命令和二进制摘要。

## 公开线索适用性表

关联编号 U01–U19 与[集中公开检索记录](upstream-security-review.md)保持一致。
版本祖先关系的原始公开 API 返回及完整合并号见
[修复身份与固定版本比较](evidence/upstream-security-review-20261007/selected-pr-identities.json)。
A＝当前配置不适用；B＝固定版本已包含对应防护；C＝自有代码或证据记录实际缺陷；
D＝预防性加固或使用约定说明；E＝资料或本轮验证不足，不能作进一步判断。
“B”只表示指定防护已经包含，不能扩展为所有安全条件已证明。

| 线索 | 分类与当前适用结论 | 排除或确认依据 | 仍有边界 |
|---|---|---|---|
| U01 FIPS 203、勘误与标准语义 | B/E：长度边界、公钥模数检查、私钥内嵌公钥哈希检查、隐式拒绝在当前代码中保留 | 封装精确长度守卫；`kem.c`的`check_pk/check_sk`与解封装路径；[独立公开向量](../tests/vectors/mlkem768.txt)与[摘要清单](../tests/vectors/SHA256SUMS) | KAT与源码审查不等于FIPS模块认证；独立向量执行须引用实际日志 |
| U02 SECURITY、公开公告与发布范围 | E：安全政策及检索记录提供判断来源，不能从公告数量推断安全 | [集中记录](upstream-security-review.md)区分当前main与固定快照 | 未覆盖私下报告、不可读社区页或未公开问题，不宣称找全漏洞 |
| U03 SOUNDNESS证明与构建前提 | E：上游证明范围和假设不能自动覆盖本项目封装、额外编译选项与实际机器 | [固定common.h](../vendor/mlkem-native/mlkem/src/common.h)、[公开证明范围](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/SOUNDNESS.md) | 本轮未重跑完整CBMC、HOL或秘密依赖动态证明；sanitizer与功能测试用途各自有限 |
| U04 [#55](https://github.com/pq-code-package/mlkem-native/pull/55)、[#460](https://github.com/pq-code-package/mlkem-native/pull/460) 编译器相关分支与比较加固 | B：固定提交在两修复之后；原消息编码沿用值屏障与安全选择，比较保留OR/XOR累积与屏障 | `compress.c`原`mlk_poly_frommsg`；`verify.h`的`mlk_ct_memcmp/mlk_ct_sel_int16`；版本比较behind=0 | 不推断所有编译器、优化条件或硬件绝对恒时；历史人工回归单独归档 |
| U05 [#1342](https://github.com/pq-code-package/mlkem-native/pull/1342) 值屏障volatile | B：已包含预防性修复，不需重复补丁 | 固定`verify.h`三处空汇编均为`__asm__ volatile`；合并号`d10fee2e16533feae5e1343692fb77f6bb2e411d`为固定版本祖先 | 维护者未报告旧屏障不安全编译实例；屏障仍不是硬件全路径恒时证明 |
| U06 [#1328](https://github.com/pq-code-package/mlkem-native/pull/1328)、[#1559](https://github.com/pq-code-package/mlkem-native/pull/1559)、[#1402](https://github.com/pq-code-package/mlkem-native/pull/1402) 清理 | B；自定义分配失败分支另为A | 固定`indcpa.c`清理`pkpv`；`kem.c`keypair错误出口清理公私钥；`common.h`含指针清理修复；当前不定义CUSTOM_ALLOC_FREE且不启用KEYGEN_PCT | 自有封装系统随机失败发生在内核之前；现合同不承诺所有调用方输出失败时清零，应只在成功后使用输出 |
| U07 [#1615](https://github.com/pq-code-package/mlkem-native/pull/1615) x86_64采样汇编边界读 | A：本项目不编译或调用该原生ASM后端；固定库也已在合并修复之后 | 有效宏不定义USE_NATIVE_BACKEND_ARITH；CMake核心为C单编译单元；固定祖先记录 | 不把非适用ASM缺陷说成本项目发生过，也不为展示切换到旧后端 |
| U08 [#1727](https://github.com/pq-code-package/mlkem-native/pull/1727) 16位int移位问题 | A：本轮本地32位int排除目标条件；固定库也已包含修复 | 有效宏`__INT_WIDTH__=32`与修复祖先关系；服务器需另核其ABI | 不外推到16位int或新硬件平台 |
| U09 [#1732](https://github.com/pq-code-package/mlkem-native/pull/1732) RV64加固 | A：RISC-V原生后端未启用；固定库包含相关合并 | CMake、有效宏与修复祖先关系 | 不能当作x86_64便携C的新修复或新检测观察 |
| U10 [#1745](https://github.com/pq-code-package/mlkem-native/pull/1745)、[#1762](https://github.com/pq-code-package/mlkem-native/pull/1762)、[#1694](https://github.com/pq-code-package/mlkem-native/pull/1694) 证明工具限制 | B/E：固定版本已在工具升级与量词范围修正之后；本项目实际证明执行仍未取得 | 公开合并与固定版本比较；CBMC注释/契约可读；不把工具问题改写为运行时漏洞 | 本輪未运行证明工具链；当前标准构建未定义CBMC，契约不作为运行时防护 |
| U11 [#1816](https://github.com/pq-code-package/mlkem-native/pull/1816)、[#1850](https://github.com/pq-code-package/mlkem-native/pull/1850)、[#1852](https://github.com/pq-code-package/mlkem-native/pull/1852) API构建、错误与测试 | B：固定版本包含；当前有效配置定义NO_RANDOMIZED_API；错误码区分参数/随机源/公钥或私钥格式错误 | 固定`common.h/mlkem_native.h`与版本比较；[现有随机失败测试](../tests/test_random_failure.c)；[源导出测试日志](evidence/defense-review-20261007/source-export.log) | 本地配置检查不等于本轮密码功能重跑；公钥/私钥公开结构校验错误不是秘密重加密标志；测试不是证明全部错误路径输出语义 |
| U12 [#1919](https://github.com/pq-code-package/mlkem-native/issues/1919)、[#1920](https://github.com/pq-code-package/mlkem-native/pull/1920) 先include头导致配置缺失 | A：固定版本未包含后续修复，但本项目包含顺序与自有平坦配置排除所述条件 | 核心编译单元未先include公共头；`common.h`先置BUILD_INTERNAL再读配置；`baseline_config.h`三定义不条件于BUILD_INTERNAL；实际有效宏已核 | 改成新的单编译单元集成顺序或复杂配置时须重审；未静默升级固定快照 |
| U13 [#1923](https://github.com/pq-code-package/mlkem-native/pull/1923) GNU-stack注记 | A：固定版本未包含后续变更，本项目不编译`mlkem_native_asm.S` | CMake不启用ASM语言且无该源目标；有效宏为便携C | 实际Linux可执行栈属性仍应由产物GNU_STACK检查；源码路径排除不代替ELF核验 |
| U14 [#1926](https://github.com/pq-code-package/mlkem-native/pull/1926) 原生ABI长度/证明接口 | A：固定版本未包含后续修改，本项目不经过原生rej_uniform汇编接口 | C核心与有效宏排除；不把原生证明接口调整归到便携C封装 | 若新增原生ASM后端须重核接口与产物，不在本轮引入 |
| U15 [#1921](https://github.com/pq-code-package/mlkem-native/issues/1921) 便携C假设乘法恒时 | E：这是当前便携C实际相关的硬件/编译前提；尚无本轮全路径或硬件层证实 | 固定`poly.c/compress.h`使用乘法；公开讨论与上游文档前提；KVM中的CPU型号字符串只能描述暴露型号 | 不把功能通过、分支检查、未显著观察或型号字符串作为乘法恒时证明；不新增触发实验 |
| U16 [#1909](https://github.com/pq-code-package/mlkem-native/issues/1909) 外部缓冲临时写 | D/E：本项目普通入口使用本地缓冲、返回后消费，未见并发观察者；可补充调用约定，不能认定不存在物理瞬时写泄露 | `mlkem.c/main.c`仅在调用返回后消费结果；接口已要求缓冲区互不重叠；`kem.c`先写拒绝密钥再条件替换 | 应用侧须保持独占缓冲并只在成功后消费；本轮没有并发、故障或物理观察评估 |
| U17 clangover作者材料/邮件、U18 KyberSlash原始研究 | A/B：旧Kyber、旧编译器或具体除法机制不能直接归为固定ML-KEM漏洞；相关防护原则在当前源码审查 | [案例档案](defensive-case.md)、[来源](sources.md)、固定屏障与比较；历史人工补丁保留身份 | 历史人工案例不是新的上游漏洞，旧平台结果不补成本轮Linux防护前后证据 |
| U19 liboqs/AWS-LC等集成讨论 | A：本项目没有该集成路径，KEM内核也未链接其运行库 | 实际构建源和链接依赖；集成项目结论按其自身来源归属 | 共同算法或相似代码不能证明问题共享；若未来采用集成必须另审 |

## 自有代码边界审查

| 检查 | 当前判断 | 检查范围与未覆盖项 |
|---|---|---|
| 空指针与长度 | B：三个公开密码封装在调用固定长度内核前拒绝空指针和非精确长度 | [现有边界与独立向量测试](../tests/test_mlkem.c)；缓冲区容量真实足够且互不重叠仍是C调用者合同，不能由指针本身证明 |
| 隐式拒绝与错误 | B：篡改/随机密文仍计算J拒绝秘密；内部比较不成为CLI状态 | 固定内核返回值不是`fail`；公钥哈希格式错误属于公开结构检查；不新增验证结果输出 |
| 安全比较与选择 | B：密码路径沿用上游累积比较、值屏障和条件移动 | 自测/KAT中的`memcmp`用于功能结果比较，不作为解封装内核密文比较；本轮不把全程序含memcmp视为内核使用不安全比较 |
| 随机源失败 | B：open/read/close失败传播，种子总在封装出口清理；read/close失败清理随机输出 | 现有失败测试实际覆盖open失败及恢复；本輪未新增read/close系统调用故障注入，不能把open测试说成三路径实测 |
| 秘密生命周期 | B/D：普通封装和CLI清理所持种子、私钥与共享秘密；上游清理中间数组 | 公共API输出由调用者持有与销毁；原随机open失败不会生成新随机数据；接口不承诺失败输出全清零；不推断寄存器、崩溃转储或物理残留已消除 |
| 日志与状态 | B：普通CLI与audit只打印公共来源、错误及检查结果，不打印私钥、共享秘密或内核比较位 | 输入类别标签来自公开生成器；既有KAT拒绝数来自公开向量比对；测试标签不等于运行时秘密验证结果 |
| audit调度边界 | B：调用使用参数数组与execvp，输出新建；当前普通入口不启动新的秘密机制计时 | 路径、失败与证据展示的产品问题由对应模块核验；这一结论不审计用户安装的同名外部程序 |

## DEF-F01：已修正的构建身份记录缺陷

实际问题是`cmake/build_configuration.txt.in`沿用未定义的`overlay_root`，使旧生成记录中的
`vulnerable_kernel_include`错误地显示为`/mlkem`。实际编译使用`overlay_root_vulnerable`，
因此问题影响证据身份一致性，未改变算法、标准语义、隐式拒绝或实际链接路径。

修正将四版核心include记录分别绑定真实vendor与三个构建副本；补充自有配置中参数集、
上游随机API禁用、便携后端配置及目标IPO属性。字段限定为`baseline_config`声明，外加
编译flags仍须独立核验。没有更改vendor、已有补丁、固定向量或封存旧产物。

验证先在新本地目录重新配置，再将身份字段与CMake生成的真实编译命令作交叉核对，检查
变体include优先顺序与有效预处理宏，并运行现有源导出失败/成功测试及format-check。
原始记录分别为[命令、时间与退出状态](evidence/defense-review-20261007/command-ledger.txt)、
[配置原始输出](evidence/defense-review-20261007/configure.log)、
[构建与格式输出](evidence/defense-review-20261007/identity-format.log)、
[源导出输出](evidence/defense-review-20261007/source-export.log)、
[交叉核对输出](evidence/defense-review-20261007/configuration-cross-check.log)。
交叉核对方法及有效输入见[检查脚本](evidence/defense-review-20261007/check_configuration.py)、
[预处理命令](evidence/defense-review-20261007/preprocessor-command.txt)、
[有效宏](evidence/defense-review-20261007/effective-macros.txt)。
上述12份记录的[SHA-256清单](evidence/defense-review-20261007/SHA256SUMS)可在该目录核对。

这些检查支持“身份记录与当前构建输入一致”。它们不能证明时序漏洞不存在或实际防护有效。
本轮Linux上的独立向量、边界、随机失败、sanitizer和产物检查应另附实际执行记录；
旧封存数据不绑定本修正生成的新身份记录，也不修改旧清单。

## 尚需保持的证据边界

公开依据、固定版本适用性、代码/配置核验、服务器运行、统计观察和防护效果六层各自报告。
当前新增的是公开适用性审查与构建身份修正核验。历史人工案例、C02有限模型、C04后赋
标签及E02普通性能的用途保持原样；代理换机器复算仍是作者代理复算。

R07的新完整受控防护前后证据仍依赖合格真实材料，不能由本记录或工程测试关闭。
具体可接受材料与剩余条件见[防护证据缺口](defense-evidence-gap.md)。实际运行截图及审批签署也不由本子任务填写。
