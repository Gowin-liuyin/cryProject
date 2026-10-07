# 新匿名成品ZIP干净验收

最终成品为candidate-round-20261007-v2，执行者是作者代理。第一版因身份差异说明遗漏
停止成品验收并保留；详情见[控制端记录](controller-attempts.md)。旧交付包均未覆盖。

最终ZIP SHA-256：b46cb573e0439cf94990e14c66cbcb533d11aa9bf687dbbb4496e02e5ffcf7c7。
源码导出清单：601a1020f30e17fc6a072d35f24f43e33acf87153f8cef8bf1c70475dad0a938。
原生同成品执行窗口：2026-10-07T16:57:44Z 至 2026-10-07T16:58:09Z，均为UTC。
授权Ubuntu24.04.4/x86_64/4vCPU/KVM实例，使用此前新目录下另一个独立package-v2目录。

[成品身份与实际结果](final-archive-identity.json)、[完整步骤/UTC/退出](native/results/step-exits.tsv)
及[执行脚本](native-execution.sh)可复核。25步全部0；ZIP校验、解压、全包/源码/C04清单全部
匹配；[GCC34项](native/results/gcc-tests.log)及[Clang ASan/UBSan34项](native/results/clang-sanitize-tests.log)
均通过。两目录产物分离，[实际产物/配置/ELF](native/results/artifact-identity.log)与
[运行版本](native/results/version.log)记录新601a导出身份，不冒称N01的2e94648源码。

40历史报告逐字一致，普通性能和精确主表逐字一致；40964模型、24576后赋标签及144
原时间均逐字一致，原比较退出见账本。新短演示60条及100预热，只验证普通入口：
[真实CSV](native/results/live/data.csv)、[meta](native/results/live/data.meta)、
[成本](native/results/live/data.csv.cost)、[原输出](native/results/live/collection.log)、
[生成的HTML](native/results/live/index.html)。这是实际程序页面，未取得界面截图，不用它
宣称正式样本或新防护效果。

[独立资料核验](independent-review.json)为另一Agent只读检查，不是真实非原作者人员。
320 HTML及697主要Markdown链接、142原数值CSV、132vendor/向量原件、50条历史映射、
18条C04副本输入全部通过；Office/PDF无项目作者姓名/邮箱/个人路径/凭据，官方原件
作者单列保留。201个N01输入相同、4个旧主动测试未分发、5处自有文本不同逐项列在
[N01分发差异](N01-distribution-differences.json)，三处仅协议身份常量，不是算法修复。
公开匿名副本的转换已记录，内部原件不改。

本轮没有新时序漏洞触发、利用、密钥恢复或受控防护实验。R07完整链、真实非原作者
执行、实际截图及签署仍缺；当前是工程可审阅的提交候选版，不称全部要求验收完成。
