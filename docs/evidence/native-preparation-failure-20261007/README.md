# 首次原生配对准备停止记录

固定源码76e6c1bc9384d1e2ca8e30e3238dfc6cda4e2a30，真实Ubuntu24.04.4/x86_64/KVM，4vCPU。
外部taskset绑定CPU2。该目录是实际失败材料，不是合成夹具；源码、账和失败日志原样保留。

bootstrap构建成功；参考前置中5项reference功能通过，后续GCC13.3构建analyze_paired失败：
结构体数组 `{{0}, {0}}` 触发-Wmissing-braces，项目-Werror保留。主流程退出2，
reference-preflight为partial，准备收据pending，cost_closure=unclosed。
共同40000调用/3600秒仍是未闭合预留上界，不是实际执行数，也不能补写为0。

遵照batch-execution-v1及paired-native-package，本轮批次合同在准备失败处停止。
K4/K16开发、候选选择及20对确认全部未执行；不重开预算、自动重试或更改门槛。
没有S、收益区间、正式中心或正式成本比值；这不是候选效果的统计否定结果。
后续修复与普通平台验收另列身份，不能把它们回填到本次快照。

snapshot-start-failure.log是bundle未选中main时的启动错误，未进入准备脚本、未创建准备目录。
outer-execution.log为空，因为正式脚本把输出记录在各step日志；不能用空文件证明成功。
目录中原reference-preflight/SHA256SUMS未产生，因流程在构建时中断。
只复制文本证据，构建缓存/二进制留在目标；分发副本另作匿名映射。
