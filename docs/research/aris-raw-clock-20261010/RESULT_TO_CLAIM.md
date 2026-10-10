# RAW空窗口结果对应声明

判定日期2026-10-10。依据[实际结果](RESULTS.md)、[事前合同](EXPERIMENT_PLAN.md)、[完整证据](../../evidence/raw-clock-20261010/run-aa43771/README.md)及[独立声明审查](../../evidence/raw-clock-20261010/run-aa43771/review-claims/RESULT_TO_CLAIM_REVIEW.md)。外部Codex MCP不可用，以下为代理判断及同模型内部独立审查，标记`[pending Codex review]`。

| 评价字段 | 判定 |
|---|---|
| claim_supported | **yes**，仅限事前固定的新Linux空窗口有限描述；完整R02目标为**partial** |
| what_results_support | 真实新普通C11产物，三个分开的完整进程，303000pair/606000采样读钟；声明1ns、观察最小正值10ns、主空窗P50为20ns/P99为21ns及全部长尾；严格C描述与完整管理接受分别留证 |
| what_results_dont_support | 物理精度或误差上界、两次读钟总成本、从旧G2扣开销、旧产物及运行时路径等价、恒频、独占、iid、跨会话或完整解封装重复性、真实总体错误率/功效、防护效果或竞赛全部签收 |
| missing_evidence | 完整普通参考负载的运行间与跨会话描述；针对目标差异量级的精度论证；正式统计对象及适用随机化/依赖条件。旧KVM可信身份和真人材料属于独立交付缺口 |
| suggested_claim_revision | 保持“明确机器及新产物下三次近邻空窗口的有限描述”，不改写为“1ns高精度平台”或“已完成R02” |
| next_experiments_needed | 另冻普通参考完整调用重复性合同，分开同会话进程与跨会话单位，保存全部逐调用原值、环境与时钟账；不重跑本次以挑选长尾更小的结果 |
| confidence | 对有限描述与字节核验为high；对泛化或正式统计确认不作置信背书 |

这次实验解决一个实际测量缺口。其观察不需要依赖安全等价界或真实FPR真值；它也不替代依赖这些对象的确认。按ARIS的partial路线，完整研究继续补证，不通过追加相同空窗口、改旧证据或重复组包提升判定。R02/R04均不签收。
