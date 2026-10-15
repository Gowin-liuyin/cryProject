# M5 接线与功能验证计划

日期：2026-10-16。范围是固定快照身份、复用构建接线、功能资格与环境草案；本轮不采集时间样本。

1. 保留 `vendor/mlkem-native/mlkem/` 与 `LICENSE` 原件，核验现有固定提交
   `b3ba7b32773e657dd37f6f87bce82528459ad8a4` 与下载的上游归档逐文件一致。
2. 复用 `mlkem_reference`、`reference_baseline`、`reference_measure`，只新增 M5 CMake 别名与聚合目标。
   参考内核不应用 message-branch 或其他人工机制补丁，M1 vendor 与封存证据保持只读。
3. 本机全新 `build/platform-s6/` 下配置普通和 ASan/UBSan 两套构建，执行已有参考资格 5 项：
   独立 NIST KAT/接口边界、随机源失败、CLI、向量解析、向量摘要；执行普通系统随机源自检。
4. 构建 `reference_measure` 并核对链接与调用路径，但不执行采数入口。不把 macOS/ARM
   功能或反汇编当作 nss-marker x86_64 定位、时序或统计结果。
5. 后续 M5 的锁频、类对、样本数、假设族、Holm 与统计电池需另行冻结 PLAN 并提交后执行。
   dudect 不进入 Holm；锁频任务由主控串行调度，必须有进出 restore_match 与退出恢复。

本轮完成标准：固定身份可复核、可调用解封装 CLI 构建成功、普通/动态参考资格通过、ENV 草案明确未执行项。
本轮无密钥恢复，无 exploit demo，无 push。
