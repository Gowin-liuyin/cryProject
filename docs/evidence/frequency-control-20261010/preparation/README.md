# 频率请求恢复预演准备件

2026-10-10。本轮仅G1空任务预演，合同见[固定计划](../../../research/aris-frequency-control-20261010/EXPERIMENT_PLAN.md)。此目录不表示已写频率或完成实机恢复。

`preflight.log/json`保存实际nss-m普通用户读取的32策略、目标拓扑、global模式与根cpuset；两对象一致。`preflight-execution.json`是实际工具返回及上下文，退出0，内存源执行没有创建远端项目文件。零写入字段是源码声明，不是动态监视器。

`local-check/`保存最终候选的实际CTest原日志与CMake缓存：1/1通过，包含16类管理/频率自检，无真实kernel配置写入。修订前有早期Python语法失败（工具8877b9），后经修正才通过；没有另存该次原stderr，不冒称初次即成功。

独立源码审查指出并在执行前修复了三项真实缺口：异步dirty请求即使当前仍显示原值也须明确重发原请求取消；取消失败时不能发布restored回执；人工恢复须同时核对probe PID/启动ticks已终止。最终单文件SHA-256为 `b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661`，独立代理 `/root/feedback_admin_review` 复核完整diff及最终LastTest，给出G1限定通过，未SSH、执行或修改文件。

四个固定字段、同一guard/管理锁、先空组再频率恢复、原min后原max、其他30策略只读及旧run兼容符合合同；观察可见恢复不证明work严格排空、隐藏QoS逐位复原、恒频或长worker生命周期。旧证据和用户修改均保留。
