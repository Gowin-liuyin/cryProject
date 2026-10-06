# 有限批次测量软件轮交接（2026-10-06）

本轮起点 `8a6f40e8ed3935574379f236d7413f88ee8e3fca`，直接main，未push。
用户明确暂无原生目标，故完成独立的软件工作，正式开发、K选择和20对确认保留待执行。
提交身份沿用已确认的Gowin-liuyin/yinhaoran0808@outlook.com，不重复询问。

| 模块 | 实际完成 | 提交/状态 |
|---|---|---|
| 0 | 冻结数学、种子、成本、中心与失败/停止规约；旧合同原样保留 | `5db7833c362b1bfb4b68d4fb7ff3418adba22cc9` |
| 1 | 公开有序输入流SHA3-256、精确成功调用计数及失败成本伴随文件 | `587e1e93724dfd3f9c5587fbed88b2158f2d1976` |
| 2 | 参考库有限K=1/4/16窗口、余数、各输出保留及计时后消费、独立批次CSV | `db8628d525b440b7a802c16ce60a1f5818eb6499` |
| 3 | C运行级median/MAD/S、成对bootstrap、数据/成本/中心/资格检查 | `35589bf6e2dbc85bd5a6dd0418db3c91ce0a3d0a` |
| 4 | 共用预算、原子工作账、预留/结算、阻塞等待期限、中断、失败保留 | `46bf5ee2736f11495405aa9c5b0121f2e70c982d` |
| 5 | C准备工具、拟议计划/种子核查、纳秒共享成本、原生运行包；Linux未执行 | `2976b6742f5bd5f869e5e7ad76cfdb0918ba6b1e` |
| 6 | 开发比较、选择一个K、确认清单冻结 | 未执行：缺原生前置；没有候选选择或确认冻结提交 |
| 7 | 原生20对确认及收益解释 | 未执行：依赖模块5真实结果及模块6选择；没有数据可升级声明 |
| 8A | 封存软件夹具、复算入口、贡献审查 | `ff1d9602e4e3d9cf52c137927d293e92ec88bbf4` |
| 8B | 作者新检出/新构建复算，报告逐字相同 | `af6bf7c2a6113a688a86baf2a1884d66e1d0732e` |
| 9 | 本交接、要求状态及原始失败材料归档 | 本文件所属交接提交，最终hash见git log和聊天交接 |

## 参考身份、实际检查和产物

内核仍为未修改mlkem-native `b3ba7b32773e657dd37f6f87bce82528459ad8a4`、ML-KEM-768便携C。
vendor、固定向量、三个人工机制补丁和原比较合同相对本轮起点零差异。
基线依然由src/measure.c加BASELINE_ORDINARY_WORKLOAD编译，保留reference_ordinary_v1六列
逐次格式，扩展信息只写meta及独立CSV.cost。候选从同一源码增加私有批次宏，只链接同一个
mlkem_reference库。未新增缺陷、主动机制采集、网络流程或密钥恢复。

Apple M5/ARM64 macOS/Apple Clang21，普通RelWithDebInfo与独立ASan/UBSan最终各12/12。
实际名称：reference_kat、reference_random_failure、reference_cli、reference_vector_parser、
vector_integrity、reference_benchmark、batch_measurement、paired_statistics、paired_data、
paired_rejections、paired_runner、paired_prepare。注册28项，不宣称全部执行。
格式、CMake格式、脚本语法、diff及证据摘要通过；六个新C源文件静态分析无诊断。
缺stdio/unused参数的初次编译失败留原日志，修正记录另存。

独立C测试检查全部共享密钥字节等价、K1/4/16与短窗口、输入摘要一致、计数守恒、
非法/溢出/零次数、覆盖及写满失败；数学手算中位数/MAD、配对倍乘恒等式、固定种子、
正负资格、零MAD/非有限数/分母退化、权重、截断、重复块、缺配对、未完成、输入/源不一致。
编排演练非零退出、缺失输出、摘要不符、预算耗尽、超时、中断和重复目录，均不生成成功汇总。
原始失败账及部分文件另封存在paired-failure-records-20261006，程序/库不复制进Git。

实际release产物摘要及反汇编见paired-software-20261006：主窗口围绕批次函数；
批次内按实际K循环调用完整mlkem_decapsulate，分别存状态、按32字节推进输出；
终点读钟后循环消费每个输出。地址只属于该摘要对应的ARM64软件产品，不冒充x86产物。
所有软件记录保留当时HEAD、未提交摘要及实际编译配置，不能当作提交后重新采样。

## 正式比较结果表：尚未执行

| 项目 | 逐次基线 | K4候选 | K16候选 |
|---|---|---|---|
| 目标平台/工具链/固定运行源码 | 原生x86_64 Linux待提供；工具链和实际运行版本未冻结 | 同左 | 同左 |
| 完整开发/确认运行对 | 0/0 | 0/0 | 0/0 |
| 实际开发/确认/预热调用 | 尚未启动 | 尚未启动 | 尚未启动 |
| 原生失败/重试 | 无正式尝试 | 无正式尝试 | 无正式尝试 |
| run_mean median、MAD、S | 未测 | 未测 | 未测 |
| S比值与99%区间 | 不可用 | 不可用 | 不可用 |
| 中心变化 | 不可用 | 不可用 | 不可用 |
| 完整墙钟及相对变化 | 未采；现场账未建立 | 未采 | 未采 |
| 最终比较资格与结论 | 证据不足 | 证据不足 | 证据不足 |
| 单次P99 | 等待基线逐次记录 | 批次记录不能获得 | 批次记录不能获得 |

每方法上限200000调用/30分钟：开发40000、确认120000、辅助/失败40000；两个K共用账。
准备包计共同调用40000上界/两方法平分，自举[0,300秒]保守墙钟，后续C纳秒计时。
每个尝试有调用和墙钟预留，失败按上界扣账，失联预留不能无声重置。
完整工作进程观察把核验/日志/结算列共同开销；最后观察记账以1秒截止和[0,1秒]上界
纳入预算。比较采用共同成本区间最不利比值，不机械扣空窗，不借上界稀释开销。
这些是已经实现的规则，不是本轮实际原生成本；软件演练账与正式预算隔离。

## 可执行入口与复算

```sh
cmake -S . -B build/paired -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/paired --target check-reference reference_benchmark reference_batch_benchmark \
    analyze_paired paired_runner paired_prepare test_batch_measurement test_reference_benchmark \
    test_paired_statistics test_paired_data test_paired_rejections test_paired_runner test_paired_prepare \
    paired_worker_fixture --parallel
ctest --test-dir build/paired --output-on-failure \
    -R '^(batch_measurement|reference_benchmark|paired_statistics|paired_data|paired_rejections|paired_runner|paired_prepare)$'
mkdir -p runs
paired_input_directory=$(mktemp -d runs/paired-interface.XXXXXX)
build/paired/reference/benchmark interface-check 42 10 "$paired_input_directory/baseline.csv" "$paired_input_directory/baseline.meta"
build/paired/reference/batch_benchmark interface-check 42 10 4 "$paired_input_directory/candidate.csv" "$paired_input_directory/candidate.meta"
sh tools/replay_paired.sh build/paired/analyze_paired \
    docs/evidence/paired-software-20261006/synthetic-cohort "$paired_input_directory/software-recomputed.report"
```

这组macOS入口只验证接口。原生前置及未来开发命令见paired-native-package.md。
确认前必须有真实前置、开发成本和选择依据、一个K、20个新种子/顺序和源/分析/产物摘要
的独立冻结提交；本轮不创建假确认清单。复算只读源数据，不要求旧构建目录存在。

## 复现与下一项任务

封存C合成20对的软件数据能在新临时检出固定ff1d960源码、全新构建目录复算；
同一ARM64工具链报告逐字相同。合成时间/成本/零身份字段明示构造，不能填入正式收益表。
这是作者自复现，没有真正非原作者日志，也没有指定设备重采。

R02/R04/R08软件链更完整；R09缺目标前置与完整受控实证，R11缺第三方，R12仍证据不足。
普通测量更平滑不能替代秘密因果定位、防护复测或检测效率提升。
贡献审查确认批次/乱序/预热/重采样属于已有方法，本轮工程价值是可审计的有限比较链，
不是算法新颖性或密码安全收益。最有价值的下一项是提供经核实目标机器并执行模块5；
然后用同一本账做两个K开发比较，条件不合格就停止而不扩大搜索。
