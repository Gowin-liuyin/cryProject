# S1 只读整合审查

审查日期：2026-10-16。最终只读审查已完成；本片段冻结，不再修改同伴代码或证据。

审查范围：S5 统计电池、M2 版本/定位证据、S7 LUT 夹具、S8 比较夹具、M5 PIN/接线及根 CMake 平台入口。
预期负载是一名操作者离线复算至多 200 万条样本，并行构建/定位但串行正式采数。
本路不修改代码、不采数、不 stage/commit/push。

## 当前结论

**可合并本轮软件与定位交付，无未解决的代码阻塞。** M3/M4 的相同功能与封装边界通过
源码交叉核对；M5 直接复用 reference，平台开关默认关闭。未发现本轮对 M1 保护目录的 diff。
S5 状态风险和来源元数据已修正，本机/Linux 合成 CTest 各 1/1 通过；M2 已有同 ELF
静态机制和 varlat 开/关定位对照。以上结论不包含 M2/M3/M4/M5 的时序统计或竞赛验收。

## 已修正的问题

1. **离线 dudect 阳性不可被后批覆盖**。
   初稿每批覆盖 `state=report(...)`；早期已检出而后批稀释差异时，最终可能写“尚无证据”。
   已改为 `has_leakage_evidence` 粘滞记录；离线回放仍明确区别于原生在线采集。

2. **RTLF 不得静默改变含零值的样本集合**。
   C 输入允许 0 ns，但钉版 RTLF `rtlf.R` 的读取流程会过滤 0；CI 与 RTLF 因而可能比较
   不同样本集。已增加 `blocked_upstream_zero_filter`：CI 留原值，RTLF 明确不运行。

3. **Shell heredoc 的变量与中文标点边界**。
   S5 首轮 CTest 日志报 `rtlf_exit_status` 与紧邻标点被当作未定义变量。
   已统一使用 `${变量名}`；新 `build/platform-s5/Testing/Temporary/LastTest.log`
   显示合成与拒绝检查通过，CTest 1/1。

## 来源元数据与文档对齐

1. **统计产物必须记录选择的类对与工具身份**。
   原初稿只写 `X/Y`、`class0/class1`，同一 measure CSV 用 `--classes valid random` 或
   `--classes message-zero message-ones` 运行后，结果未记录选项，复算无法辨认实际类对。
   已补入 `summary.json` 的 `input_format/class0_name/class1_name`、
   `configuration.txt` 的路径/机型及 `tools.sha256`。
   类名只允许安全 ASCII 字符，工具路径不插入 JSON，避免引号与反斜杠破坏格式。

2. **架构的派生 CSV 说明须对齐 S5 实际接口**。
   架构最初采用 M1 的类名二列表；S5 当前 wide 输入固定为
   `class0_ns,class1_ns`，内部 RTLF/离线 dudect 输入是 `V1,V2` 标签/耗时长表。
   长表能保留类别不等长和采集原序，是合理适配；主控已将架构更新为当前协议，
   并明确宽表交错顺序由适配器构造、两列不自动构成配对数据。

## 已核对的正确性与边界

- CSV 数值仅接受十进制非负整数，拒绝负数、NaN、额外字段、截断行、混合 run/implementation
  和非 ns 单位；超过 double 精确整数范围拒绝，不静默舍入。保留原输入，不覆盖既有输出目录。
- C 统计复用现有 `timing_statistics.c`，明确报告正态近似 CI/p，不冒称精确 Student-t；
  不自行构建 Holm 家族。原生 dudect 日志只标记导入且来源未核验，不伪装成新实跑。
- M3 开版查秘密下标，关版固定顺序扫描全部 256 项；掩码选择对 0–255 下标成立，
  先完成 32 字节变换再写输出，保持原地及部分重叠语义。自检独立对照公开仿射映射。
- M4 两版均只返回相等性；封装先检查指针及 32 字节长度，自检对照 `memcmp(...) == 0`。
  ct 名称标明实现意图，Binsec 未实跑时不声称 secure。
- M3 原生 Memcheck 日志是开版 32 errors / 1 context、关版 0；M4 是 vulnerable 32 / 1、ct 0。
  日志命中实际夹具源位置，动态产物没有混入计时或完整 KEM 结果。
- 原生定位工作根分别为 `/home/nss-marker/yhr/Cry/platform-s7-20261016-idAExSCX` 与
  `/home/nss-marker/yhr/Cry/platform-s8-20261016-250f424b`，日志中的临时目录位于该根内。
- M5 PIN 记录固定提交、126 文件逐字核对与导入范围；接线别名指向未打补丁的 `mlkem_reference`。
  普通/sanitizer 的 5/5 功能资格与尚未执行的原生阴性定位/统计分开写。
- 根平台开关 `BASELINE_ENABLE_PLATFORM` 默认 OFF；平台 CMake 只加入独立统计入口和夹具，
  没有覆写 M1 的构建选项、vendor 或既有结论。格式检查仅扩展到新自有代码，不格式化 vendor。

## 最终原件与产物复核

复核只读取归档，不执行被测密码路径，也不新增时间样本。

| 对象 | 独立核对 | 结果 |
|---|---|---|
| M2 源码 | `linux-original.tar.gz` 内 source-poison 两 vendor 对上游清单及当前本地快照 | 各 123/123 个 Git 条目的字节/符号链接目标匹配；自有 CMake 与探针也逐字一致 |
| M2 产物 | 内存解析归档的 ELF64 头与符号表，并重算 SHA-256 | 两份 Machine=62（x86-64），摘要与 `SHA256SUMS`、ENV、VERSION_AUDIT 一致 |
| M2 静态/动态对应 | 同 ELF 三函数、六反汇编片段、varlat=yes/no 与退出日志 | 未修目标各一条 div、已修各零；yes 为 1280/3 对 0/0，no 两版均 0/0 |
| M3 来源 | 原资格包摘要与其中四个夹具源文件 | 包 SHA-256 与 ENV 一致，4/4 源文件匹配当前文件，原生开/关日志及源位置与 RESULT 一致 |
| M4 来源与产物 | `complete-v2.tar.gz` 内十个源文件及四个 ELF | 10/10 源文件逐字匹配，四 ELF 重新计算摘要均与清单一致；v1 警告包未被当作最终完整性依据 |
| S5 来源 | v2 `SOURCE_EXPORT.sha256` 与当前自有输入 | 执行、测试及构建八文件匹配；README 在实跑后补说明，明确不将当前文档倒写成执行时源码 |
| S5 软件实跑 | 完整资格包、CTest、RTLF JSON/退出、dudect 离线日志 | 本机/Linux CTest 各 1/1；100/类合成偏移 RTLF exit11、等分布 exit10；60000 行离线回放阳性/无证据如实区分 |

M2 两份原包 ELF 的独立 SHA-256：

```text
unfixed c29fc3e9b44d010ae7145eecc3dec61d7fbe66cd761f0852703df5206bb2f125
fixed   f5c062d61a5108d3bc5d0643d661a28dfef2483a661c06270e1815a4db86e730
```

S5 完整资格包独立 SHA-256 为
`cf7a4293531dacacd430f562ebe07304d8c1d30ce67777a6211c070228a7df21`。
包内首轮五点 RTLF 失败保留原样，v2 的每类至少 100 条门控已处理；不删除失败来制造成功。

M2 默认日志的 `poly_tomsg` 上下文 PC `0x400185d` 对应同一 ELF 的系数 load，
不是静态 `div` 地址 `0x1877`。已独立读取归档字节确认，VERSION_AUDIT/RESULT 已明确此边界。
定位依赖同一产物的数据流与 varlat 开/关对照，不能逐地址声称默认上下文 PC 就是除法。
这也不证明 Ryzen 上该次除法具有可测物理延迟，更不证明端到端可区分。

## 保留范围与未检查项

- 本路不独立重跑主控最终聚合 CTest。主控报告新增 ASan/UBSan 7/7；普通聚合检查以
  主控最终日志为准。S1 核对的是已保存的各路软件日志、源文件和产物关联。
- M3 本地资格包只包含固定源码与原生摘要/反汇编/工具日志，未包含 ELF 原件；
  完整构建仍保存在其远端 Cry 根，本路没有再次读取远端 ELF。不能把该项写成 S1 已重算本地 ELF。
- S5 资格包包含源清单、构建日志、ELF 摘要及合成结果，完整上传源/ELF 留在远端；
  合成阳性/无证据只验证接口，不是 M2 或 M5 的统计结论，也不是新的在线 dudect。
- M2 只运行三个上游热点；未执行完整 KEM、独立 KAT、端到端或微基准采数，参数家族仍为空。
- M3/M4 是独立人工校准夹具；尚无时序统计。Microwalk/Pin、Binsec 仍阻塞，不把缺工具写成通过。
- M5 只有钉版、接线、功能资格及调用链；尚无原生动态阴性或锁频统计，不声称全套工具不误报。
- 对全部 `vendor/liboqs-0.10.0/` 与 `docs/evidence/liboqs010-*`、`tooling-strengthen-*`、
  `r02-r04-*` 检查 `git diff 4a3a4ab --name-only` 无改动；本轮不重新签收或改写 M1。

给主控：可提交本最终审查片段并冻结；后续先补适用功能资格和预注册采数合同，再开展
单一锁频任务。当前软件/定位完成与正式统计未运行必须同时保留。
